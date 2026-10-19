output "application_id" {
  description = "ID of the service's AppConfig Application"
  value = aws_appconfig_application.service.id
}

output "application_name" {
  description = "Name of the service's AppConfig Application, which publishAppConfig looks it up by"
  value = aws_appconfig_application.service.name
}

output "environment_ids" {
  description = "IDs of the service's AppConfig Environments, keyed by Environment name"
  value = { for name, environment in aws_appconfig_environment.service : name => environment.environment_id }
}

output "configuration_profile_id" {
  description = "ID of the service's runtime-settings Configuration Profile"
  value = aws_appconfig_configuration_profile.runtime_settings.configuration_profile_id
}

output "configuration_profile_name" {
  description = "Name of the Configuration Profile, which publishAppConfig looks it up by"
  value = aws_appconfig_configuration_profile.runtime_settings.name
}

output "deployment_strategy_id" {
  description = "ID of AWS's predefined Canary10Percent20Minutes deployment strategy (10% of instances first, then a bake), which publishAppConfig deploys with. Predefined, so there is nothing to create, and a Terraform strategy of the same name would be a different one with a generated ID that nothing uses (ADR-0011)"
  value = "AppConfig.Canary10Percent20Minutes"
}
