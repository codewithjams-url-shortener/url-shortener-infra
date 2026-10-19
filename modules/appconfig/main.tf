resource "aws_appconfig_application" "service" {
  name = var.service_name
  description = "Runtime configuration for ${var.service_name} (ADR-0011)"
}

resource "aws_appconfig_environment" "service" {
  for_each = var.environment_names

  application_id = aws_appconfig_application.service.id
  name = each.key
  description = "The ${each.key} environment of ${var.service_name}'s runtime configuration"
}

resource "aws_appconfig_configuration_profile" "runtime_settings" {
  application_id = aws_appconfig_application.service.id
  name = "runtime-settings"
  description = "Feature flags and live-tunable settings for ${var.service_name}, published from its config repo"
  location_uri = "hosted"
  type = "AWS.Freeform"

  dynamic "validator" {
    for_each = var.config_schema == null ? [] : [var.config_schema]

    content {
      type = "JSON_SCHEMA"
      content = validator.value
    }

  }

}
