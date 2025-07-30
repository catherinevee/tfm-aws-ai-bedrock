# Advanced example for Amazon Bedrock + Lambda + API Gateway module
# This example demonstrates all features including security, monitoring, and advanced configurations

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

# SNS Topic for CloudWatch alarms
resource "aws_sns_topic" "alerts" {
  name = "bedrock-api-alerts"
  
  tags = {
    Environment = "production"
    Project     = "bedrock-api"
  }
}

# SNS Topic subscription (email)
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "admin@example.com"
}

module "bedrock_api" {
  source = "../../"

  name_prefix = "production-bedrock-api"
  
  # Bedrock Configuration
  bedrock_model_id = "anthropic.claude-3-sonnet-20240229-v1:0"
  max_tokens       = 2000
  temperature      = 0.7
  top_p           = 0.9
  
  # Lambda Configuration
  lambda_runtime   = "python3.11"
  lambda_timeout   = 60
  lambda_memory_size = 1024
  log_level        = "INFO"
  
  # API Gateway Configuration
  api_stage_name = "v1"
  enable_cors    = true
  cors_allowed_origins = [
    "https://myapp.com",
    "https://admin.myapp.com",
    "https://api.myapp.com"
  ]
  cors_allowed_methods = ["GET", "POST", "OPTIONS"]
  cors_allowed_headers = [
    "Content-Type",
    "Authorization",
    "X-Requested-With",
    "X-API-Key"
  ]
  
  # Security Configuration
  enable_waf        = true
  waf_rate_limit    = 5000
  enable_api_key    = true
  api_key_name      = "production-bedrock-api-key"
  usage_plan_name   = "production-bedrock-usage-plan"
  rate_limit        = 100
  burst_limit       = 200
  
  # Monitoring Configuration
  enable_monitoring = true
  log_retention_days = 30
  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]
  
  tags = {
    Environment = "production"
    Project     = "bedrock-api"
    Team        = "ai-ml"
    CostCenter  = "ai-ml"
    Owner       = "data-science-team"
    ManagedBy   = "terraform"
  }
}

# Outputs
output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = module.bedrock_api.api_gateway_url
}

output "api_key_id" {
  description = "API Key ID for authentication"
  value       = module.bedrock_api.api_key_id
}

output "api_key_value" {
  description = "API Key value (sensitive)"
  value       = module.bedrock_api.api_key_value
  sensitive   = true
}

output "waf_web_acl_id" {
  description = "WAF Web ACL ID"
  value       = module.bedrock_api.waf_web_acl_id
}

output "cloudwatch_alarms" {
  description = "CloudWatch alarm names"
  value       = module.bedrock_api.cloudwatch_alarm_names
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = module.bedrock_api.lambda_function_arn
}

output "usage_plan_id" {
  description = "Usage plan ID"
  value       = module.bedrock_api.usage_plan_id
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
} 