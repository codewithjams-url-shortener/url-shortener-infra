output "alarm_arn" {
  description = "ARN of the service's 5xx-rate alarm, to hand to the appconfig module as the rollback trigger"
  value = aws_cloudwatch_metric_alarm.five_xx_rate.arn
}

output "alarm_name" {
  description = "Name of the service's 5xx-rate alarm"
  value = aws_cloudwatch_metric_alarm.five_xx_rate.alarm_name
}

output "monitor_role_arn" {
  description = "ARN of the IAM role AppConfig assumes to read the alarm, to hand to the appconfig module alongside alarm_arn"
  value = aws_iam_role.appconfig_monitor.arn
}
