# Amazon Bedrock + Lambda + API Gateway Terraform Module
# This module creates a complete serverless AI solution using Amazon Bedrock, Lambda, and API Gateway

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.name_prefix}-bedrock-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Lambda to access Bedrock
resource "aws_iam_policy" "bedrock_policy" {
  name        = "${var.name_prefix}-bedrock-policy"
  description = "Policy for Lambda to access Amazon Bedrock"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = var.bedrock_model_arns
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}

# Attach policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_bedrock_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.bedrock_policy.arn
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.name_prefix}-bedrock-lambda"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Lambda Function
resource "aws_lambda_function" "bedrock_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.name_prefix}-bedrock-lambda"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size

  environment {
    variables = {
      BEDROCK_MODEL_ID = var.bedrock_model_id
      LOG_LEVEL        = var.log_level
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_bedrock_policy,
    aws_cloudwatch_log_group.lambda_logs
  ]

  tags = var.tags
}

# Lambda function code archive
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"
  source {
    content = templatefile("${path.module}/lambda_function.py", {
      bedrock_model_id = var.bedrock_model_id
      max_tokens       = var.max_tokens
      temperature      = var.temperature
      top_p           = var.top_p
    })
    filename = "index.py"
  }
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "bedrock_api" {
  name        = "${var.name_prefix}-bedrock-api"
  description = "API Gateway for Amazon Bedrock Lambda integration"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

# API Gateway Resource
resource "aws_api_gateway_resource" "bedrock_resource" {
  rest_api_id = aws_api_gateway_rest_api.bedrock_api.id
  parent_id   = aws_api_gateway_rest_api.bedrock_api.root_resource_id
  path_part   = "bedrock"
}

# API Gateway Method
resource "aws_api_gateway_method" "bedrock_method" {
  rest_api_id   = aws_api_gateway_rest_api.bedrock_api.id
  resource_id   = aws_api_gateway_resource.bedrock_resource.id
  http_method   = "POST"
  authorization = var.enable_api_key ? "NONE" : "NONE"
  api_key_required = var.enable_api_key
}

# API Gateway OPTIONS method for CORS
resource "aws_api_gateway_method" "bedrock_options" {
  count         = var.enable_cors ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.bedrock_api.id
  resource_id   = aws_api_gateway_resource.bedrock_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# API Gateway OPTIONS integration for CORS
resource "aws_api_gateway_integration" "bedrock_options_integration" {
  count                   = var.enable_cors ? 1 : 0
  rest_api_id             = aws_api_gateway_rest_api.bedrock_api.id
  resource_id             = aws_api_gateway_resource.bedrock_resource.id
  http_method             = aws_api_gateway_method.bedrock_options[0].http_method
  type                    = "MOCK"
  request_templates       = { "application/json" = "{\"statusCode\": 200}" }
  passthrough_behavior    = "WHEN_NO_MATCH"
  content_handling        = "CONVERT_TO_TEXT"
}

# API Gateway OPTIONS method response for CORS
resource "aws_api_gateway_method_response" "bedrock_options_200" {
  count       = var.enable_cors ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.bedrock_api.id
  resource_id = aws_api_gateway_resource.bedrock_resource.id
  http_method = aws_api_gateway_method.bedrock_options[0].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# API Gateway OPTIONS integration response for CORS
resource "aws_api_gateway_integration_response" "bedrock_options_integration_response" {
  count       = var.enable_cors ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.bedrock_api.id
  resource_id = aws_api_gateway_resource.bedrock_resource.id
  http_method = aws_api_gateway_method.bedrock_options[0].http_method
  status_code = aws_api_gateway_method_response.bedrock_options_200[0].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'${join(",", var.cors_allowed_headers)}'"
    "method.response.header.Access-Control-Allow-Methods" = "'${join(",", var.cors_allowed_methods)}'"
    "method.response.header.Access-Control-Allow-Origin"  = "'${join(",", var.cors_allowed_origins)}'"
  }
}

# API Gateway Integration
resource "aws_api_gateway_integration" "bedrock_integration" {
  rest_api_id = aws_api_gateway_rest_api.bedrock_api.id
  resource_id = aws_api_gateway_resource.bedrock_resource.id
  http_method = aws_api_gateway_method.bedrock_method.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.bedrock_lambda.invoke_arn
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bedrock_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.bedrock_api.execution_arn}/*/*"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "bedrock_deployment" {
  depends_on = [
    aws_api_gateway_integration.bedrock_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.bedrock_api.id
  stage_name  = var.api_stage_name

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "bedrock_stage" {
  deployment_id = aws_api_gateway_deployment.bedrock_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.bedrock_api.id
  stage_name    = var.api_stage_name

  tags = var.tags
}

# CloudWatch Alarms for Lambda
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.name_prefix}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors lambda function errors"
  alarm_actions       = var.alarm_actions

  dimensions = {
    FunctionName = aws_lambda_function.bedrock_lambda.function_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.name_prefix}-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = var.lambda_timeout * 1000 * 0.8 # 80% of timeout
  alarm_description   = "This metric monitors lambda function duration"
  alarm_actions       = var.alarm_actions

  dimensions = {
    FunctionName = aws_lambda_function.bedrock_lambda.function_name
  }

  tags = var.tags
}

# WAF Web ACL for API Gateway (optional)
resource "aws_wafv2_web_acl" "api_gateway_waf" {
  count = var.enable_waf ? 1 : 0

  name        = "${var.name_prefix}-api-gateway-waf"
  description = "WAF for API Gateway"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "RateLimitRule"
    priority = 1

    override_action {
      none {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "RateLimitRule"
      sampled_requests_enabled  = true
    }
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled  = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "APIGatewayWAF"
    sampled_requests_enabled  = true
  }

  tags = var.tags
}

# WAF Web ACL Association with API Gateway
resource "aws_wafv2_web_acl_association" "api_gateway" {
  count = var.enable_waf ? 1 : 0

  resource_arn = aws_api_gateway_stage.bedrock_stage.arn
  web_acl_arn  = aws_wafv2_web_acl.api_gateway_waf[0].arn
}

# API Gateway API Key (optional)
resource "aws_api_gateway_api_key" "bedrock_api_key" {
  count = var.enable_api_key ? 1 : 0
  name  = var.api_key_name
  tags  = var.tags
}

# API Gateway Usage Plan (optional)
resource "aws_api_gateway_usage_plan" "bedrock_usage_plan" {
  count = var.enable_api_key ? 1 : 0
  name  = var.usage_plan_name

  api_stages {
    api_id = aws_api_gateway_rest_api.bedrock_api.id
    stage  = aws_api_gateway_stage.bedrock_stage.stage_name
  }

  throttle_settings {
    rate_limit  = var.rate_limit
    burst_limit = var.burst_limit
  }

  tags = var.tags
}

# API Gateway Usage Plan Key (optional)
resource "aws_api_gateway_usage_plan_key" "bedrock_usage_plan_key" {
  count         = var.enable_api_key ? 1 : 0
  key_id        = aws_api_gateway_api_key.bedrock_api_key[0].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.bedrock_usage_plan[0].id
} 