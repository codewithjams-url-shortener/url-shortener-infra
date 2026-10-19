# Like the appconfig module's tests, these run against a mocked AWS provider. floci neither stores a metric-math alarm's
# queries (it returns them as null, so a real apply would show permanent drift) nor ever evaluates an alarm, so a real
# apply would prove nothing beyond the call being accepted. The alarm's real behaviour is only checkable in AWS.

# The role ARN is given its real shape, since the provider validates it where it is used.
mock_provider "aws" {

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::000000000000:role/test-service-appconfig-monitor"
    }
  }

}

run "creates_an_alarm_named_after_the_service" {

  command = apply

  variables {
    service_name = "test-service"
  }

  assert {
    condition = output.alarm_name == "test-service-5xx-rate"
    error_message = "Alarm name did not follow the service name"
  }

  assert {
    condition = output.alarm_arn != "" && output.monitor_role_arn != ""
    error_message = "Expected the alarm and the monitor role ARNs to be exposed"
  }

}

run "matches_adr_0011_by_default" {

  command = plan

  variables {
    service_name = "test-service"
  }

  assert {
    condition = aws_cloudwatch_metric_alarm.five_xx_rate.threshold == 5 && aws_cloudwatch_metric_alarm.five_xx_rate.comparison_operator == "GreaterThanThreshold"
    error_message = "The default threshold must be a 5xx rate above 5%"
  }

  assert {
    condition = aws_cloudwatch_metric_alarm.five_xx_rate.evaluation_periods == 2 && aws_cloudwatch_metric_alarm.five_xx_rate.datapoints_to_alarm == 2
    error_message = "The default window must be 2 consecutive 60 second periods"
  }

  assert {
    condition = alltrue([for q in aws_cloudwatch_metric_alarm.five_xx_rate.metric_query : q.metric == null || length(q.metric) == 0 || q.metric[0].period == 60])
    error_message = "The default period must be 60 seconds"
  }

}

run "computes_the_rate_from_the_two_counts_and_guards_low_traffic" {

  command = plan

  variables {
    service_name = "test-service"
  }

  assert {
    condition = length([for q in aws_cloudwatch_metric_alarm.five_xx_rate.metric_query : q if q.id == "rate" && q.return_data == true && q.expression == "IF(requests >= 20, 100 * errors / requests, 0)"]) == 1
    error_message = "Only the rate expression must be returned, and it must ignore periods under the minimum request count"
  }

  assert {
    condition = length([for q in aws_cloudwatch_metric_alarm.five_xx_rate.metric_query : q if q.id == "errors" || q.id == "requests"]) == 2
    error_message = "Expected one query each for the error and the request counts"
  }

}

run "reads_both_counts_from_the_services_own_dimension" {

  command = plan

  variables {
    service_name = "test-service"
  }

  assert {
    condition = alltrue([
      for q in aws_cloudwatch_metric_alarm.five_xx_rate.metric_query :
      q.metric[0].namespace == "UrlShortener" && q.metric[0].dimensions == tomap({ Service = "test-service" }) && q.metric[0].stat == "Sum"
      if q.id == "errors" || q.id == "requests"
    ])
    error_message = "Both counts must be summed from the UrlShortener namespace under this service's Service dimension"
  }

  assert {
    condition = length([for q in aws_cloudwatch_metric_alarm.five_xx_rate.metric_query : q if q.id == "errors" && q.metric[0].metric_name == "Http5xxCount"]) == 1 && length([for q in aws_cloudwatch_metric_alarm.five_xx_rate.metric_query : q if q.id == "requests" && q.metric[0].metric_name == "HttpRequestCount"]) == 1
    error_message = "The error and request counts must use the shared contract's metric names"
  }

}

run "applies_overridden_settings" {

  command = plan

  variables {
    service_name = "test-service"
    namespace = "Other"
    dimension_name = "App"
    error_metric_name = "Errors"
    request_metric_name = "Requests"
    threshold_percent = 10
    period_seconds = 120
    evaluation_periods = 3
    minimum_requests = 50
    treat_missing_data = "breaching"
  }

  assert {
    condition = aws_cloudwatch_metric_alarm.five_xx_rate.threshold == 10 && aws_cloudwatch_metric_alarm.five_xx_rate.evaluation_periods == 3 && aws_cloudwatch_metric_alarm.five_xx_rate.datapoints_to_alarm == 3 && aws_cloudwatch_metric_alarm.five_xx_rate.treat_missing_data == "breaching"
    error_message = "Overridden threshold, window and missing-data handling were not applied"
  }

  assert {
    condition = length([for q in aws_cloudwatch_metric_alarm.five_xx_rate.metric_query : q if q.id == "rate" && q.expression == "IF(requests >= 50, 100 * errors / requests, 0)"]) == 1
    error_message = "The overridden minimum request count was not applied"
  }

  assert {
    condition = alltrue([
      for q in aws_cloudwatch_metric_alarm.five_xx_rate.metric_query :
      q.metric[0].namespace == "Other" && q.metric[0].dimensions == tomap({ App = "test-service" }) && q.metric[0].period == 120
      if q.id == "errors" || q.id == "requests"
    ])
    error_message = "Overridden namespace, dimension and period were not applied to the count queries"
  }

}

run "lets_only_appconfig_assume_the_monitor_role_and_only_to_describe_alarms" {

  command = plan

  variables {
    service_name = "test-service"
  }

  assert {
    condition = jsondecode(aws_iam_role.appconfig_monitor.assume_role_policy).Statement[0].Principal.Service == "appconfig.amazonaws.com"
    error_message = "Only the AppConfig service may assume the monitor role"
  }

  assert {
    condition = jsondecode(aws_iam_role_policy.appconfig_monitor.policy).Statement[0].Action == "cloudwatch:DescribeAlarms"
    error_message = "The monitor role must be allowed to describe alarms and nothing else"
  }

  assert {
    condition = aws_iam_role.appconfig_monitor.name == "test-service-appconfig-monitor"
    error_message = "The monitor role must be named after the service"
  }

}

run "rejects_a_service_name_the_appconfig_application_would_not_have" {

  command = plan

  variables {
    service_name = "Test_Service"
  }

  expect_failures = [var.service_name]

}

run "rejects_a_threshold_outside_zero_to_one_hundred_percent" {

  command = plan

  variables {
    service_name = "test-service"
    threshold_percent = 0
  }

  expect_failures = [var.threshold_percent]

}

run "rejects_a_period_that_is_not_a_multiple_of_sixty_seconds" {

  command = plan

  variables {
    service_name = "test-service"
    period_seconds = 90
  }

  expect_failures = [var.period_seconds]

}

run "rejects_a_missing_data_treatment_cloudwatch_does_not_know" {

  command = plan

  variables {
    service_name = "test-service"
    treat_missing_data = "maybe"
  }

  expect_failures = [var.treat_missing_data]

}

run "rejects_zero_evaluation_periods" {

  command = plan

  variables {
    service_name = "test-service"
    evaluation_periods = 0
  }

  expect_failures = [var.evaluation_periods]

}

run "rejects_a_negative_minimum_request_count" {

  command = plan

  variables {
    service_name = "test-service"
    minimum_requests = -1
  }

  expect_failures = [var.minimum_requests]

}
