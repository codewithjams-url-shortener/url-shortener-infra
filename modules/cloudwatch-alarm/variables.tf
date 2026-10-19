variable "service_name" {
  description = "Name of the service the alarm watches. It is the value of the metric's service dimension, and it names the alarm and the AppConfig monitor role"
  type = string

  validation {
    condition = can(regex("^[a-z0-9][a-z0-9-]*$", var.service_name))
    error_message = "service_name must be lowercase letters, digits and hyphens, matching the AppConfig Application it guards"
  }

}

variable "namespace" {
  description = "CloudWatch namespace the services publish their request counts to. Must match the shared metric contract in service-common"
  type = string
  default = "UrlShortener"
}

variable "dimension_name" {
  description = "Name of the metric dimension that carries the service name. Must match the shared metric contract in service-common"
  type = string
  default = "Service"
}

variable "error_metric_name" {
  description = "Name of the metric counting a service's 5xx responses. Must match the shared metric contract in service-common"
  type = string
  default = "Http5xxCount"
}

variable "request_metric_name" {
  description = "Name of the metric counting all of a service's responses. Must match the shared metric contract in service-common"
  type = string
  default = "HttpRequestCount"
}

variable "threshold_percent" {
  description = "5xx share of all responses, in percent, above which the alarm fires (ADR-0011: 5)"
  type = number
  default = 5

  validation {
    condition = var.threshold_percent > 0 && var.threshold_percent <= 100
    error_message = "threshold_percent must be above 0 and at most 100"
  }

}

variable "period_seconds" {
  description = "Length in seconds of each evaluation period. CloudWatch standard-resolution metrics need a multiple of 60"
  type = number
  default = 60

  validation {
    condition = var.period_seconds >= 60 && var.period_seconds % 60 == 0
    error_message = "period_seconds must be a multiple of 60"
  }

}

variable "evaluation_periods" {
  description = "Number of consecutive periods the rate must exceed the threshold before the alarm fires, so the window is period_seconds times this (ADR-0011: 2 minutes)"
  type = number
  default = 2

  validation {
    condition = var.evaluation_periods >= 1
    error_message = "evaluation_periods must be at least 1"
  }

}

variable "minimum_requests" {
  description = "Responses a period needs before its 5xx rate counts. Below it the rate is taken as 0, so one failed request out of a handful cannot roll back a healthy configuration"
  type = number
  default = 20

  validation {
    condition = var.minimum_requests >= 0
    error_message = "minimum_requests must not be negative"
  }

}

variable "treat_missing_data" {
  description = "How a period without any datapoints is treated. notBreaching keeps a quiet service from rolling back a deployment; the cost is that a service which stopped publishing cannot trigger one"
  type = string
  default = "notBreaching"

  validation {
    condition = contains(["notBreaching", "breaching", "ignore", "missing"], var.treat_missing_data)
    error_message = "treat_missing_data must be one of notBreaching, breaching, ignore or missing"
  }

}
