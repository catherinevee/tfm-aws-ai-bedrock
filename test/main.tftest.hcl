run "basic_module_verification" {
  command = plan

  assert {
    condition     = module.bedrock_api.api_gateway_url != ""
    error_message = "API Gateway URL must not be empty"
  }

  assert {
    condition     = module.bedrock_api.lambda_function_name != ""
    error_message = "Lambda function name must not be empty"
  }

  assert {
    condition     = module.bedrock_api.cloudwatch_log_group_name != ""
    error_message = "CloudWatch log group name must not be empty"
  }
}

run "validate_required_variables" {
  command = plan

  variables {
    name_prefix = "test-bedrock"
    tags = {
      Environment = "test"
      Project     = "bedrock-test"
    }
  }

  assert {
    condition     = length(var.tags) > 0
    error_message = "Tags must not be empty"
  }

  assert {
    condition     = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "Name prefix must contain only lowercase letters, numbers, and hyphens"
  }
}

run "validate_bedrock_model" {
  command = plan

  variables {
    name_prefix     = "test-bedrock"
    bedrock_model_id = "anthropic.claude-3-sonnet-20240229-v1:0"
  }

  assert {
    condition     = can(regex("^[a-zA-Z0-9.-]+:[0-9]+$", var.bedrock_model_id))
    error_message = "Bedrock model ID must be in the format 'provider.model:version'"
  }
}
