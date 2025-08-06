# Core Configuration
variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "bedrock-api"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "Name prefix must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "bedrock-api"
    ManagedBy   = "terraform"
  }
}

# Bedrock Model Configuration
variable "bedrock_model_id" {
  description = "Bedrock model ID (e.g., anthropic.claude-3-sonnet-20240229-v1:0)"
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

variable "bedrock_model_arns" {
  description = "List of Bedrock model ARNs Lambda can access"
  type        = list(string)
  default = [
    "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0",
    "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-haiku-20240307-v1:0",
    "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-text-express-v1"
  ]
}

# Lambda Configuration
variable "lambda_runtime" {
  description = "Python runtime version"
  type        = string
  default     = "python3.11"

  validation {
    condition = contains([
      "python3.8", "python3.9", "python3.10", "python3.11", "python3.12"
    ], var.lambda_runtime)
    error_message = "Must be a supported Python runtime version."
  }
}

variable "lambda_timeout" {
  description = "Function timeout in seconds (1-900)"
  type        = number
  default     = 30

  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "Timeout must be between 1 and 900 seconds."
  }
}

variable "lambda_memory_size" {
  description = "Memory allocation in MB (128-10240)"
  type        = number
  default     = 512

  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "Memory must be between 128 and 10240 MB."
  }
}

variable "log_level" {
  description = "Lambda logging level"
  type        = string
  default     = "INFO"

  validation {
    condition = contains(["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"], var.log_level)
    error_message = "Must be valid log level."
  }
}

variable "log_retention_days" {
  description = "CloudWatch log retention period"
  type        = number
  default     = 14

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Must be valid CloudWatch retention period."
  }
}

variable "enable_cloudwatch_logs_encryption" {
  description = "Enable KMS encryption for CloudWatch logs"
  type        = bool
  default     = false
}

variable "cloudwatch_kms_key_id" {
  description = "KMS key ID/ARN/Alias for CloudWatch logs encryption. Defaults to AWS-managed key if not specified."
  type        = string
  default     = null
  sensitive   = true
}

variable "vpc_subnet_ids" {
  description = "List of VPC subnet IDs for Lambda function. If provided, function will be deployed in VPC."
  type        = list(string)
  default     = null
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs for Lambda function VPC configuration"
  type        = list(string)
  default     = null
}

variable "waf_geo_restrictions" {
  description = "List of allowed country codes for WAF geo restriction"
  type        = list(string)
  default     = ["US", "CA", "GB"]
}

variable "enable_waf" {
  description = "Enable WAF protection for the API Gateway"
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "Rate limit for WAF rules (requests per 5 minutes)"
  type        = number
  default     = 2000
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing for Lambda and API Gateway"
  type        = bool
  default     = false
}

variable "secondary_regions" {
  description = "List of secondary regions for multi-region deployment"
  type        = list(string)
  default     = []
}

variable "auth_type" {
  description = "API Gateway authorization type (NONE, AWS_IAM, COGNITO)"
  type        = string
  default     = "NONE"
  
  validation {
    condition     = contains(["NONE", "AWS_IAM", "COGNITO"], var.auth_type)
    error_message = "Auth type must be one of: NONE, AWS_IAM, COGNITO"
  }
}

variable "cognito_user_pool_arn" {
  description = "ARN of Cognito User Pool for API authorization"
  type        = string
  default     = null
  sensitive   = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention must be one of the allowed values: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653."
  }
}

variable "api_stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "prod"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.api_stage_name))
    error_message = "API stage name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "max_tokens" {
  description = "Maximum number of tokens to generate"
  type        = number
  default     = 1000

  validation {
    condition     = var.max_tokens >= 1 && var.max_tokens <= 4096
    error_message = "Max tokens must be between 1 and 4096."
  }
}

variable "temperature" {
  description = "Temperature for text generation (0.0 to 1.0)"
  type        = number
  default     = 0.7

  validation {
    condition     = var.temperature >= 0.0 && var.temperature <= 1.0
    error_message = "Temperature must be between 0.0 and 1.0."
  }
}

variable "top_p" {
  description = "Top-p sampling parameter (0.0 to 1.0)"
  type        = number
  default     = 0.9

  validation {
    condition     = var.top_p >= 0.0 && var.top_p <= 1.0
    error_message = "Top-p must be between 0.0 and 1.0."
  }
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring and alarms"
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "List of ARNs for CloudWatch alarm actions (e.g., SNS topics)"
  type        = list(string)
  default     = []
}

variable "enable_waf" {
  description = "Enable WAF for API Gateway"
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "WAF rate limit per 5 minutes"
  type        = number
  default     = 2000

  validation {
    condition     = var.waf_rate_limit >= 100 && var.waf_rate_limit <= 2000000
    error_message = "WAF rate limit must be between 100 and 2,000,000."
  }
}

variable "enable_cors" {
  description = "Enable CORS for API Gateway"
  type        = bool
  default     = true
}

variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
}

variable "cors_allowed_methods" {
  description = "List of allowed HTTP methods for CORS"
  type        = list(string)
  default     = ["GET", "POST", "OPTIONS"]

  validation {
    condition = alltrue([
      for method in var.cors_allowed_methods : contains([
        "GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS"
      ], method)
    ])
    error_message = "CORS allowed methods must be valid HTTP methods."
  }
}

variable "cors_allowed_headers" {
  description = "List of allowed headers for CORS"
  type        = list(string)
  default     = ["Content-Type", "Authorization", "X-Requested-With"]
}

variable "enable_api_key" {
  description = "Enable API key authentication"
  type        = bool
  default     = false
}

variable "api_key_name" {
  description = "Name for the API key"
  type        = string
  default     = "bedrock-api-key"
}

variable "usage_plan_name" {
  description = "Name for the usage plan"
  type        = string
  default     = "bedrock-usage-plan"
}

variable "rate_limit" {
  description = "API Gateway rate limit per second"
  type        = number
  default     = 10

  validation {
    condition     = var.rate_limit >= 1 && var.rate_limit <= 10000
    error_message = "Rate limit must be between 1 and 10,000 requests per second."
  }
}

variable "burst_limit" {
  description = "API Gateway burst limit"
  type        = number
  default     = 20

  validation {
    condition     = var.burst_limit >= 1 && var.burst_limit <= 5000
    error_message = "Burst limit must be between 1 and 5,000."
  }
}

# VPC Configuration (Optional)
variable "vpc_subnet_ids" {
  description = "VPC subnet IDs for Lambda (optional)"
  type        = list(string)
  default     = null
}

variable "vpc_security_group_ids" {
  description = "VPC security group IDs for Lambda (optional)"
  type        = list(string)
  default     = null
} 