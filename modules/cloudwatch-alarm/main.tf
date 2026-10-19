locals {
  alarm_name = "${var.service_name}-5xx-rate"
}

# Fires when the share of responses that are 5xx stays above the threshold for the whole window. Both counts are summed
# per period and combined by metric math, because the services publish counts and CloudWatch has no ratio of its own.
resource "aws_cloudwatch_metric_alarm" "five_xx_rate" {
  alarm_name = local.alarm_name
  alarm_description = "${var.service_name} 5xx rate above ${var.threshold_percent}% for ${var.evaluation_periods} x ${var.period_seconds}s, rolls back its AppConfig deployment (ADR-0011)"
  comparison_operator = "GreaterThanThreshold"
  threshold = var.threshold_percent
  evaluation_periods = var.evaluation_periods
  datapoints_to_alarm = var.evaluation_periods
  treat_missing_data = var.treat_missing_data

  metric_query {
    id = "errors"

    metric {
      namespace = var.namespace
      metric_name = var.error_metric_name
      dimensions = { (var.dimension_name) = var.service_name }
      period = var.period_seconds
      stat = "Sum"
    }

  }

  metric_query {
    id = "requests"

    metric {
      namespace = var.namespace
      metric_name = var.request_metric_name
      dimensions = { (var.dimension_name) = var.service_name }
      period = var.period_seconds
      stat = "Sum"
    }

  }

  metric_query {
    id = "rate"
    label = "5xx rate (%)"
    expression = "IF(requests >= ${var.minimum_requests}, 100 * errors / requests, 0)"
    return_data = true
  }

}

# AppConfig assumes this role to read the alarm's state while a deployment bakes. Without it the Environment's monitor
# cannot be attached.
resource "aws_iam_role" "appconfig_monitor" {
  name = "${var.service_name}-appconfig-monitor"
  description = "Lets AppConfig read the ${local.alarm_name} alarm to decide whether to roll back a deployment"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "appconfig.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })

}

resource "aws_iam_role_policy" "appconfig_monitor" {
  name = "describe-alarms"
  role = aws_iam_role.appconfig_monitor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "cloudwatch:DescribeAlarms"
      Resource = "*"
    }]
  })

}
