# Variables for Amazon Bedrock + Lambda + API Gateway Terraform Module

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "bedrock-api"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "Name prefix must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "bedrock-api"
    ManagedBy   = "terraform"
  }
}

variable "bedrock_model_id" {
  description = "Amazon Bedrock model ID to use"
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"

  validation {
    condition = can(regex("^[a-zA-Z0-9.-]+:[0-9]+$", var.bedrock_model_id))
    error_message = "Bedrock model ID must be in the format 'provider.model:version'."
  }
}

variable "bedrock_model_arns" {
  description = "List of Bedrock model ARNs that Lambda can access"
  type        = list(string)
  default = [
    "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0",
    "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-haiku-20240307-v1:0",
    "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-text-express-v1"
  ]
}

variable "lambda_runtime" {
  description = "Lambda function runtime"
  type        = string
  default     = "python3.11"

  validation {
    condition = contains([
      "python3.8",
      "python3.9",
      "python3.10",
      "python3.11",
      "python3.12"
    ], var.lambda_runtime)
    error_message = "Lambda runtime must be a supported Python version."
  }
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30

  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "Lambda timeout must be between 1 and 900 seconds."
  }
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512

  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "Lambda memory size must be between 128 and 10240 MB."
  }
}

variable "log_level" {
  description = "Log level for Lambda function"
  type        = string
  default     = "INFO"

  validation {
    condition = contains([
      "DEBUG",
      "INFO",
      "WARNING",
      "ERROR",
      "CRITICAL"
    ], var.log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARNING, ERROR, CRITICAL."
  }
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

# ==============================================================================
# Enhanced AI/ML Configuration Variables
# ==============================================================================

variable "ai_config" {
  description = "AI/ML configuration"
  type = object({
    enable_model_invocation_logging = optional(bool, true)
    enable_model_metrics = optional(bool, true)
    enable_model_performance_monitoring = optional(bool, true)
    enable_model_quality_monitoring = optional(bool, false)
    enable_model_bias_detection = optional(bool, false)
    enable_model_explainability = optional(bool, false)
    enable_model_drift_detection = optional(bool, false)
    enable_model_versioning = optional(bool, true)
    enable_model_rollback = optional(bool, true)
    enable_model_ab_testing = optional(bool, false)
    enable_model_canary_deployment = optional(bool, false)
    enable_model_blue_green_deployment = optional(bool, false)
    enable_model_feature_store = optional(bool, false)
    enable_model_experiment_tracking = optional(bool, false)
    enable_model_hyperparameter_tuning = optional(bool, false)
    enable_model_automl = optional(bool, false)
    enable_model_mlops = optional(bool, false)
    enable_model_governance = optional(bool, false)
    enable_model_compliance = optional(bool, false)
    enable_model_security = optional(bool, true)
    enable_model_privacy = optional(bool, false)
    enable_model_fairness = optional(bool, false)
    enable_model_interpretability = optional(bool, false)
    enable_model_robustness = optional(bool, false)
  })
  default = {}
}

variable "bedrock_models" {
  description = "Map of Bedrock models to configure"
  type = map(object({
    model_id = string
    model_arn = string
    inference_type = optional(string, "ON_DEMAND")
    customizations = optional(list(string), [])
    output_modalities = optional(list(string), ["TEXT"])
    input_modalities = optional(list(string), ["TEXT"])
    supported_inference_types = optional(list(string), ["ON_DEMAND"])
    supported_customizations = optional(list(string), [])
    supported_output_modalities = optional(list(string), ["TEXT"])
    supported_input_modalities = optional(list(string), ["TEXT"])
    provider_name = optional(string, null)
    model_name = optional(string, null)
    model_arn = optional(string, null)
    model_version = optional(string, null)
    model_arn = optional(string, null)
    model_arn = optional(string, null)
    model_arn = optional(string, null)
    model_arn = optional(string, null)
    model_arn = optional(string, null)
    model_arn = optional(string, null)
  }))
  default = {}
}

variable "lambda_ai_config" {
  description = "Lambda AI configuration"
  type = object({
    enable_bedrock_invocation = optional(bool, true)
    enable_bedrock_streaming = optional(bool, false)
    enable_bedrock_async = optional(bool, false)
    enable_bedrock_batch = optional(bool, false)
    enable_bedrock_embeddings = optional(bool, false)
    enable_bedrock_fine_tuning = optional(bool, false)
    enable_bedrock_guardrails = optional(bool, false)
    enable_bedrock_knowledge_bases = optional(bool, false)
    enable_bedrock_agents = optional(bool, false)
    enable_bedrock_workflows = optional(bool, false)
    enable_bedrock_playgrounds = optional(bool, false)
    enable_bedrock_experiments = optional(bool, false)
    enable_bedrock_models = optional(bool, true)
    enable_bedrock_invocation_logging = optional(bool, true)
    enable_bedrock_metrics = optional(bool, true)
    enable_bedrock_monitoring = optional(bool, true)
    enable_bedrock_alerting = optional(bool, true)
    enable_bedrock_dashboard = optional(bool, true)
    enable_bedrock_audit_logging = optional(bool, true)
    enable_bedrock_backup = optional(bool, false)
    enable_bedrock_disaster_recovery = optional(bool, false)
  })
  default = {}
}

variable "api_gateway_ai_config" {
  description = "API Gateway AI configuration"
  type = object({
    enable_ai_rate_limiting = optional(bool, true)
    enable_ai_throttling = optional(bool, true)
    enable_ai_caching = optional(bool, false)
    enable_ai_compression = optional(bool, true)
    enable_ai_encryption = optional(bool, true)
    enable_ai_authentication = optional(bool, true)
    enable_ai_authorization = optional(bool, true)
    enable_ai_audit_logging = optional(bool, true)
    enable_ai_monitoring = optional(bool, true)
    enable_ai_alerting = optional(bool, true)
    enable_ai_dashboard = optional(bool, true)
    enable_ai_analytics = optional(bool, false)
    enable_ai_insights = optional(bool, false)
    enable_ai_reporting = optional(bool, false)
    enable_ai_backup = optional(bool, false)
    enable_ai_disaster_recovery = optional(bool, false)
  })
  default = {}
}

variable "monitoring_ai_config" {
  description = "AI monitoring configuration"
  type = object({
    enable_model_performance_monitoring = optional(bool, true)
    enable_model_quality_monitoring = optional(bool, false)
    enable_model_bias_monitoring = optional(bool, false)
    enable_model_drift_monitoring = optional(bool, false)
    enable_model_explainability_monitoring = optional(bool, false)
    enable_model_fairness_monitoring = optional(bool, false)
    enable_model_robustness_monitoring = optional(bool, false)
    enable_model_security_monitoring = optional(bool, true)
    enable_model_privacy_monitoring = optional(bool, false)
    enable_model_compliance_monitoring = optional(bool, false)
    enable_model_governance_monitoring = optional(bool, false)
    enable_model_mlops_monitoring = optional(bool, false)
    enable_model_experiment_monitoring = optional(bool, false)
    enable_model_feature_monitoring = optional(bool, false)
    enable_model_data_monitoring = optional(bool, true)
    enable_model_inference_monitoring = optional(bool, true)
    enable_model_training_monitoring = optional(bool, false)
    enable_model_deployment_monitoring = optional(bool, true)
    enable_model_rollback_monitoring = optional(bool, true)
    enable_model_version_monitoring = optional(bool, true)
    enable_model_ab_testing_monitoring = optional(bool, false)
    enable_model_canary_monitoring = optional(bool, false)
    enable_model_blue_green_monitoring = optional(bool, false)
    enable_model_feature_store_monitoring = optional(bool, false)
    enable_model_hyperparameter_monitoring = optional(bool, false)
    enable_model_automl_monitoring = optional(bool, false)
  })
  default = {}
}

variable "security_ai_config" {
  description = "AI security configuration"
  type = object({
    enable_model_encryption = optional(bool, true)
    enable_model_access_control = optional(bool, true)
    enable_model_audit_logging = optional(bool, true)
    enable_model_compliance = optional(bool, false)
    enable_model_governance = optional(bool, false)
    enable_model_privacy = optional(bool, false)
    enable_model_fairness = optional(bool, false)
    enable_model_bias_detection = optional(bool, false)
    enable_model_explainability = optional(bool, false)
    enable_model_interpretability = optional(bool, false)
    enable_model_robustness = optional(bool, false)
    enable_model_adversarial_protection = optional(bool, false)
    enable_model_poisoning_protection = optional(bool, false)
    enable_model_extraction_protection = optional(bool, false)
    enable_model_inversion_protection = optional(bool, false)
    enable_model_membership_inference_protection = optional(bool, false)
    enable_model_model_inversion_protection = optional(bool, false)
    enable_model_attribute_inference_protection = optional(bool, false)
    enable_model_property_inference_protection = optional(bool, false)
    enable_model_reconstruction_protection = optional(bool, false)
    enable_model_extraction_protection = optional(bool, false)
    enable_model_stealing_protection = optional(bool, false)
    enable_model_evasion_protection = optional(bool, false)
    enable_model_poisoning_protection = optional(bool, false)
    enable_model_backdoor_protection = optional(bool, false)
    enable_model_trojan_protection = optional(bool, false)
    enable_model_trigger_protection = optional(bool, false)
  })
  default = {}
} 