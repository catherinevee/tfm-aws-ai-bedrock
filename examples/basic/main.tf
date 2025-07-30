# Basic example for Amazon Bedrock + Lambda + API Gateway module

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

module "bedrock_api" {
  source = "../../"

  name_prefix = "basic-bedrock-api"
  
  # Basic configuration with defaults
  bedrock_model_id = "anthropic.claude-3-haiku-20240307-v1:0"
  
  # Lambda configuration
  lambda_timeout   = 30
  lambda_memory_size = 512
  
  # API Gateway configuration
  api_stage_name = "dev"
  
  # Monitoring
  enable_monitoring = true
  log_retention_days = 7
  
  tags = {
    Environment = "development"
    Project     = "bedrock-api-demo"
    Team        = "ai-team"
  }
}

# Output the API endpoint
output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = module.bedrock_api.api_gateway_url
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.bedrock_api.lambda_function_name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = module.bedrock_api.cloudwatch_log_group_name
} 