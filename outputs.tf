# Primary API outputs
output "api_gateway_url" {
  description = "API endpoint URL for Bedrock requests"
  value       = "${aws_api_gateway_stage.bedrock_stage.invoke_url}/bedrock"
}

output "api_gateway_rest_api_id" {
  description = "API Gateway REST API identifier"
  value       = aws_api_gateway_rest_api.bedrock_api.id
}

# Lambda function outputs
output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.bedrock_lambda.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.bedrock_lambda.arn
}

output "lambda_role_arn" {
  description = "Lambda execution role ARN"
  value       = aws_iam_role.lambda_role.arn
}

# Monitoring outputs
output "cloudwatch_log_group_name" {
  description = "CloudWatch log group for Lambda"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "cloudwatch_alarm_names" {
  description = "CloudWatch alarm names (if monitoring enabled)"
  value = var.enable_monitoring ? [
    aws_cloudwatch_metric_alarm.lambda_errors[0].alarm_name,
    aws_cloudwatch_metric_alarm.lambda_duration[0].alarm_name
  ] : []
}

# Security outputs
output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN (if WAF enabled)"
  value       = var.enable_waf ? aws_wafv2_web_acl.api_gateway_waf[0].arn : null
}

output "api_key_id" {
  description = "API key identifier (if API key enabled)"
  value       = var.enable_api_key ? aws_api_gateway_api_key.bedrock_api_key[0].id : null
}

output "api_key_value" {
  description = "API key value (if API key enabled)"
  value       = var.enable_api_key ? aws_api_gateway_api_key.bedrock_api_key[0].value : null
  sensitive   = true
} 