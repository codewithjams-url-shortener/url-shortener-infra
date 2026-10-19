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

variable "alarm_arn" {
  description = "ARN of the CloudWatch alarm AppConfig watches while a deployment bakes, rolling it back if it fires. Null attaches none, so deployments are never rolled back automatically. Comes with monitor_role_arn from the cloudwatch-alarm module (ADR-0011)"
  type = string
  default = null
}

variable "monitor_role_arn" {
  description = "ARN of the IAM role AppConfig assumes to read alarm_arn. Required with it and meaningless without it"
  type = string
  default = null

  validation {
    condition = (var.alarm_arn == null) == (var.monitor_role_arn == null)
    error_message = "alarm_arn and monitor_role_arn must be given together: AppConfig cannot read an alarm without a role, and a role with no alarm does nothing"
  }

}
