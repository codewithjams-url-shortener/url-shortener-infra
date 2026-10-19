variable "service_name" {
  description = "Name of the service whose runtime configuration this manages. It becomes the AppConfig Application's name, which is how the publishAppConfig pipeline step finds it (ADR-0011)"
  type = string

  validation {
    condition = can(regex("^[a-z0-9][a-z0-9-]*$", var.service_name))
    error_message = "service_name must be lowercase letters, digits and hyphens, matching what publishAppConfig accepts"
  }

}

variable "environment_names" {
  description = "Names of the AppConfig Environments to create for the service, e.g. [\"local\"] in the local Terraform root and [\"aws\"] in the AWS one. publishAppConfig deploys to the Environment named after its environment parameter"
  type = set(string)

  validation {
    condition = length(var.environment_names) > 0
    error_message = "At least one Environment name is required"
  }

}

variable "config_schema" {
  description = "JSON Schema content attached to the Configuration Profile as a validator, so AppConfig itself rejects a config that violates it. Null attaches none, leaving the pipeline's own schema check as the only one (floci does not enforce profile validators regardless)"
  type = string
  default = null
}
