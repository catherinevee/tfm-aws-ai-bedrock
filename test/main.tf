# Test configuration for Amazon Bedrock + Lambda + API Gateway module

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Test module with minimal configuration
module "bedrock_api_test" {
  source = "../"

  name_prefix = "test-bedrock-api"
  
  # Use a faster model for testing
  bedrock_model_id = "anthropic.claude-3-haiku-20240307-v1:0"
  
  # Minimal configuration for testing
  lambda_timeout   = 30
  lambda_memory_size = 512
  api_stage_name = "test"
  
  # Disable expensive features for testing
  enable_waf = false
  enable_api_key = false
  enable_monitoring = false
  log_retention_days = 1
  
  tags = {
    Environment = "test"
    Project     = "bedrock-api-test"
    TestRun     = "true"
  }
}

# Outputs for testing
output "test_api_endpoint" {
  description = "Test API Gateway endpoint URL"
  value       = module.bedrock_api_test.api_gateway_url
}

output "test_lambda_function_name" {
  description = "Test Lambda function name"
  value       = module.bedrock_api_test.lambda_function_name
}

output "test_lambda_function_arn" {
  description = "Test Lambda function ARN"
  value       = module.bedrock_api_test.lambda_function_arn
}

output "test_api_gateway_rest_api_id" {
  description = "Test API Gateway REST API ID"
  value       = module.bedrock_api_test.api_gateway_rest_api_id
}

output "test_cloudwatch_log_group_name" {
  description = "Test CloudWatch log group name"
  value       = module.bedrock_api_test.cloudwatch_log_group_name
} 