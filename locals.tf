locals {
  lambda_name = "${var.name_prefix}-bedrock-lambda"
  api_name    = "${var.name_prefix}-bedrock-api"
  s3_bucket   = "${var.name_prefix}-lambda-artifacts-${data.aws_caller_identity.current.account_id}"
  
  # Common tags
  common_tags = merge(var.tags, {
    Terraform   = "true"
    Module      = "aws-bedrock"
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  # IAM role and policy names
  role_name   = "${var.name_prefix}-bedrock-lambda-role"
  policy_name = "${var.name_prefix}-bedrock-policy"

  # CloudWatch log group
  log_group_name = "/aws/lambda/${local.lambda_name}"
  
  # Default WAF rules
  default_waf_rules = var.enable_waf ? {
    rate_limit = {
      name     = "rate-limit"
      priority = 1
      limit    = var.waf_rate_limit
    }
    geo_restriction = {
      name     = "geo-restriction"
      priority = 2
      rules    = var.waf_geo_restrictions
    }
  } : {}

  # API Gateway settings
  api_gateway_settings = {
    metrics_enabled      = true
    logging_level       = "INFO"
    data_trace_enabled  = var.environment != "prod"
    xray_tracing_enabled = var.enable_xray_tracing
  }

  # Lambda settings
  lambda_settings = {
    architectures = ["arm64"]  # Using ARM for better price/performance
    publish      = true        # Enable versioning
    tracing_mode = var.enable_xray_tracing ? "Active" : "PassThrough"
  }

  # Regional settings
  multi_region = length(var.secondary_regions) > 0
  regions = distinct(concat([data.aws_region.current.name], var.secondary_regions))

  # Authorization settings
  auth_type = var.auth_type != null ? var.auth_type : "NONE"
  authorizer_settings = var.auth_type == "COGNITO" ? {
    type                   = "COGNITO_USER_POOLS"
    identity_source        = "method.request.header.Authorization"
    provider_arns         = [var.cognito_user_pool_arn]
  } : {}
}
