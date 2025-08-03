# Enterprise Example - Full Security Configuration

provider "aws" {
  region = "us-west-2"
}

# KMS key for encryption
resource "aws_kms_key" "logs" {
  description             = "KMS key for CloudWatch logs encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Environment = "production"
    Project     = "ai-platform"
  }
}

# VPC for Lambda function
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "ai-service-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false
  
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = "production"
    Project     = "ai-platform"
  }
}

# Security group for Lambda
resource "aws_security_group" "lambda" {
  name        = "bedrock-lambda-sg"
  description = "Security group for Bedrock Lambda function"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "production"
    Project     = "ai-platform"
  }
}

# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "ai-service-users"

  password_policy {
    minimum_length    = 12
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  mfa_configuration = "OPTIONAL"

  tags = {
    Environment = "production"
    Project     = "ai-platform"
  }
}

# Bedrock API Module
module "bedrock_api" {
  source = "../../"

  name_prefix     = "enterprise-ai"
  environment     = "prod"
  bedrock_model_id = "anthropic.claude-3-sonnet-20240229-v1:0"
  
  # VPC Configuration
  vpc_subnet_ids         = module.vpc.private_subnets
  vpc_security_group_ids = [aws_security_group.lambda.id]

  # Security Settings
  enable_cloudwatch_logs_encryption = true
  cloudwatch_kms_key_id            = aws_kms_key.logs.id
  enable_xray_tracing              = true

  # WAF Protection
  enable_waf           = true
  waf_rate_limit      = 1000
  waf_geo_restrictions = ["US", "CA", "GB", "DE", "FR"]

  # API Authentication
  auth_type             = "COGNITO"
  cognito_user_pool_arn = aws_cognito_user_pool.main.arn

  tags = {
    Environment = "production"
    Project     = "ai-platform"
    CostCenter  = "12345"
    Owner       = "platform-team"
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "ai-service-metrics"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", module.bedrock_api.lambda_function_name],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = "us-west-2"
          title  = "Lambda Metrics"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiName", module.bedrock_api.api_name],
            [".", "4XXError", ".", "."],
            [".", "5XXError", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = "us-west-2"
          title  = "API Gateway Metrics"
        }
      }
    ]
  })
}

# Outputs
output "api_endpoint" {
  description = "The API Gateway endpoint URL"
  value       = module.bedrock_api.api_endpoint
}

output "cognito_pool_id" {
  description = "The Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "vpc_id" {
  description = "The VPC ID"
  value       = module.vpc.vpc_id
}

output "cloudwatch_dashboard_url" {
  description = "The CloudWatch Dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=us-west-2#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}
