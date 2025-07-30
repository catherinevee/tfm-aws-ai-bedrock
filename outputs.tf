# Outputs for Amazon Bedrock + Lambda + API Gateway Terraform Module

output "api_gateway_url" {
  description = "URL of the API Gateway endpoint"
  value       = "${aws_api_gateway_stage.bedrock_stage.invoke_url}/bedrock"
}

output "api_gateway_rest_api_id" {
  description = "ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.bedrock_api.id
}

output "api_gateway_stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.bedrock_stage.stage_name
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.bedrock_lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.bedrock_lambda.arn
}

output "lambda_function_invoke_arn" {
  description = "Invocation ARN of the Lambda function"
  value       = aws_lambda_function.bedrock_lambda.invoke_arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda_role.name
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda_logs.arn
}

output "bedrock_policy_arn" {
  description = "ARN of the Bedrock access policy"
  value       = aws_iam_policy.bedrock_policy.arn
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL (if enabled)"
  value       = var.enable_waf ? aws_wafv2_web_acl.api_gateway_waf[0].arn : null
}

output "waf_web_acl_id" {
  description = "ID of the WAF Web ACL (if enabled)"
  value       = var.enable_waf ? aws_wafv2_web_acl.api_gateway_waf[0].id : null
}

output "cloudwatch_alarm_names" {
  description = "Names of CloudWatch alarms (if monitoring enabled)"
  value = var.enable_monitoring ? [
    aws_cloudwatch_metric_alarm.lambda_errors[0].alarm_name,
    aws_cloudwatch_metric_alarm.lambda_duration[0].alarm_name
  ] : []
}

output "module_version" {
  description = "Version of this Terraform module"
  value       = "1.0.0"
}

output "bedrock_model_id" {
  description = "Bedrock model ID being used"
  value       = var.bedrock_model_id
}

output "lambda_runtime" {
  description = "Lambda runtime being used"
  value       = var.lambda_runtime
}

output "lambda_timeout" {
  description = "Lambda timeout in seconds"
  value       = var.lambda_timeout
}

output "lambda_memory_size" {
  description = "Lambda memory size in MB"
  value       = var.lambda_memory_size
}

output "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.bedrock_api.execution_arn
}

output "tags" {
  description = "Tags applied to all resources"
  value       = var.tags
}

output "api_key_id" {
  description = "ID of the API Gateway API key (if enabled)"
  value       = var.enable_api_key ? aws_api_gateway_api_key.bedrock_api_key[0].id : null
}

output "api_key_value" {
  description = "Value of the API Gateway API key (if enabled)"
  value       = var.enable_api_key ? aws_api_gateway_api_key.bedrock_api_key[0].value : null
  sensitive   = true
}

output "usage_plan_id" {
  description = "ID of the API Gateway usage plan (if enabled)"
  value       = var.enable_api_key ? aws_api_gateway_usage_plan.bedrock_usage_plan[0].id : null
}

output "rate_limit" {
  description = "API Gateway rate limit per second"
  value       = var.rate_limit
}

output "burst_limit" {
  description = "API Gateway burst limit"
  value       = var.burst_limit
} 