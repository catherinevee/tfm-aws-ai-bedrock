# Basic example for Amazon Bedrock + Lambda + API Gateway module

terraform {
  required_version = "~> 1.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Region where Bedrock is available
}

module "bedrock_api" {
  source = "../../"

  name_prefix = "basic-example"
  
  # Basic configuration with defaults
  bedrock_model_id = "anthropic.claude-3-sonnet-20240229-v1:0"
  
  # Lambda configuration
  lambda_timeout   = 30
  lambda_memory_size = 512
  
  # API Gateway configuration
  api_stage_name = "dev"
  
  # Monitoring
  enable_monitoring = true
  log_retention_days = 7
  
  tags = {
    Environment = "dev"
    Project     = "example"
    ManagedBy   = "terraform"
  }
}

# Outputs
output "api_url" {
  description = "API Gateway endpoint URL"
  value       = module.bedrock_api.api_gateway_url
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.bedrock_api.lambda_function_name
}

output "cloudwatch_log_group" {
  description = "Name of the CloudWatch log group"
  value       = module.bedrock_api.cloudwatch_log_group_name
}
  description = "Lambda function name"
  value       = module.bedrock_api.lambda_function_name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = module.bedrock_api.cloudwatch_log_group_name
} 