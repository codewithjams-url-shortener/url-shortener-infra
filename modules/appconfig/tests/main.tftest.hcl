# Unlike the other modules' tests, these run against a mocked AWS provider rather than a real apply against floci.
# `terraform test` always destroys what it creates when a run finishes, and floci's AppConfig answers DeleteEnvironment
# with a bogus S3 NoSuchBucket 404, so a real apply here would always end with a failed teardown and leave the Application
# behind in floci. The mock exercises this module's own logic with no such problem; that the real provider works against
# floci's AppConfig was checked separately with a scratch apply.

# The IDs are given AppConfig's real shape (4-7 lowercase letters or digits), since the provider validates the ones it is
# handed between resources and the mock would otherwise generate random strings that fail it.
mock_provider "aws" {

  mock_resource "aws_appconfig_application" {
    defaults = {
      id = "app1234"
    }
  }

  mock_resource "aws_appconfig_environment" {
    defaults = {
      id = "env1234:app1234"
      environment_id = "env1234"
    }
  }

  mock_resource "aws_appconfig_configuration_profile" {
    defaults = {
      id = "prf1234:app1234"
      configuration_profile_id = "prf1234"
    }
  }

}

run "creates_application_environment_and_profile" {

  command = apply

  variables {
    service_name = "test-service"
    environment_names = ["local"]
  }

  assert {
    condition = output.application_name == "test-service"
    error_message = "Application name did not match the service name"
  }

  assert {
    condition = output.application_id != ""
    error_message = "Expected a non-empty Application ID"
  }

  assert {
    condition = length(output.environment_ids) == 1 && contains(keys(output.environment_ids), "local")
    error_message = "Expected exactly the requested local Environment"
  }

  assert {
    condition = output.configuration_profile_name == "runtime-settings"
    error_message = "The Configuration Profile must be named runtime-settings, which publishAppConfig looks it up by"
  }

  assert {
    condition = output.deployment_strategy_id == "AppConfig.Canary10Percent20Minutes"
    error_message = "Expected the predefined Canary10Percent20Minutes strategy"
  }

}

run "creates_one_environment_per_name" {

  command = apply

  variables {
    service_name = "test-service"
    environment_names = ["local", "aws"]
  }

  assert {
    condition = length(output.environment_ids) == 2
    error_message = "Expected one Environment per requested name"
  }

  assert {
    condition = contains(keys(output.environment_ids), "local") && contains(keys(output.environment_ids), "aws")
    error_message = "Environments must be keyed by their names, which publishAppConfig looks them up by"
  }

}

run "uses_hosted_freeform_profile_without_a_validator_by_default" {

  command = plan

  variables {
    service_name = "test-service"
    environment_names = ["local"]
  }

  assert {
    condition = aws_appconfig_configuration_profile.runtime_settings.location_uri == "hosted"
    error_message = "Config is published into AppConfig as hosted versions, so the profile must be hosted"
  }

  assert {
    condition = aws_appconfig_configuration_profile.runtime_settings.type == "AWS.Freeform"
    error_message = "Expected a freeform profile"
  }

  assert {
    condition = length(aws_appconfig_configuration_profile.runtime_settings.validator) == 0
    error_message = "No validator should be attached when no schema is given"
  }

}

run "attaches_the_json_schema_as_a_validator_when_given" {

  command = plan

  variables {
    service_name = "test-service"
    environment_names = ["local"]
    config_schema = "{\"type\":\"object\"}"
  }

  assert {
    condition = length(aws_appconfig_configuration_profile.runtime_settings.validator) == 1
    error_message = "Expected the schema to be attached as the profile's one validator"
  }

  assert {
    condition = one(aws_appconfig_configuration_profile.runtime_settings.validator).type == "JSON_SCHEMA"
    error_message = "The validator must be a JSON Schema one"
  }

  assert {
    condition = one(aws_appconfig_configuration_profile.runtime_settings.validator).content == "{\"type\":\"object\"}"
    error_message = "The validator must carry the given schema unchanged"
  }

}

run "rejects_a_service_name_publishAppConfig_would_refuse" {

  command = plan

  variables {
    service_name = "Not_A_Valid_Name"
    environment_names = ["local"]
  }

  expect_failures = [var.service_name]

}

run "rejects_an_empty_set_of_environments" {

  command = plan

  variables {
    service_name = "test-service"
    environment_names = []
  }

  expect_failures = [var.environment_names]

}

run "attaches_no_monitor_by_default" {

  command = plan

  variables {
    service_name = "test-service"
    environment_names = ["local"]
  }

  assert {
    condition = length(aws_appconfig_environment.service["local"].monitor) == 0
    error_message = "Without an alarm no monitor may be attached, or deployments could never finish"
  }

}

run "attaches_the_alarm_as_a_monitor_to_every_environment_when_given" {

  command = plan

  variables {
    service_name = "test-service"
    environment_names = ["local", "aws"]
    alarm_arn = "arn:aws:cloudwatch:us-west-2:000000000000:alarm:test-service-5xx-rate"
    monitor_role_arn = "arn:aws:iam::000000000000:role/test-service-appconfig-monitor"
  }

  assert {
    condition = alltrue([
      for environment in aws_appconfig_environment.service :
      length(environment.monitor) == 1
      && one(environment.monitor).alarm_arn == "arn:aws:cloudwatch:us-west-2:000000000000:alarm:test-service-5xx-rate"
      && one(environment.monitor).alarm_role_arn == "arn:aws:iam::000000000000:role/test-service-appconfig-monitor"
    ])
    error_message = "Every Environment must watch the alarm through the given role"
  }

}

run "rejects_an_alarm_without_a_role_to_read_it" {

  command = plan

  variables {
    service_name = "test-service"
    environment_names = ["local"]
    alarm_arn = "arn:aws:cloudwatch:us-west-2:000000000000:alarm:test-service-5xx-rate"
  }

  expect_failures = [var.monitor_role_arn]

}

run "rejects_a_role_without_an_alarm_to_read" {

  command = plan

  variables {
    service_name = "test-service"
    environment_names = ["local"]
    monitor_role_arn = "arn:aws:iam::000000000000:role/test-service-appconfig-monitor"
  }

  expect_failures = [var.monitor_role_arn]

}
