# Amazon Bedrock + Lambda + API Gateway Terraform Module

A comprehensive Terraform module for deploying a serverless AI solution using Amazon Bedrock, AWS Lambda, and API Gateway. This module provides a complete infrastructure setup for creating AI-powered APIs with enterprise-grade features including monitoring, security, and scalability.

## Features

- **Amazon Bedrock Integration**: Support for multiple Bedrock models (Claude, Titan, etc.)
- **Serverless Architecture**: Lambda function with automatic scaling
- **API Gateway**: RESTful API with CORS support
- **Security**: Optional WAF protection and API key authentication
- **Monitoring**: CloudWatch alarms and logging
- **Flexible Configuration**: Extensive customization options
- **Best Practices**: Follows AWS and Terraform best practices

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate permissions
- Amazon Bedrock access enabled in your AWS account
- Required AWS permissions for the services used

### Required AWS Permissions

The deploying user/role needs the following permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:CreatePolicy",
        "iam:AttachRolePolicy",
        "iam:PassRole",
        "lambda:CreateFunction",
        "lambda:CreateEventSourceMapping",
        "lambda:AddPermission",
        "apigateway:*",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "cloudwatch:PutMetricAlarm",
        "wafv2:*",
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": "*"
    }
  ]
}
```

## Usage

### Basic Example

```hcl
module "bedrock_api" {
  source = "./tfm-aws-ai-bedrock"

  name_prefix = "my-ai-api"
  
  tags = {
    Environment = "production"
    Project     = "ai-api"
    Team        = "data-science"
  }
}
```

### Advanced Example with All Features

```hcl
module "bedrock_api" {
  source = "./tfm-aws-ai-bedrock"

  name_prefix = "production-ai-api"
  
  # Bedrock Configuration
  bedrock_model_id = "anthropic.claude-3-sonnet-20240229-v1:0"
  max_tokens       = 2000
  temperature      = 0.7
  top_p           = 0.9
  
  # Lambda Configuration
  lambda_runtime   = "python3.11"
  lambda_timeout   = 60
  lambda_memory_size = 1024
  
  # API Gateway Configuration
  api_stage_name = "v1"
  enable_cors    = true
  cors_allowed_origins = ["https://myapp.com", "https://admin.myapp.com"]
  
  # Security Configuration
  enable_waf        = true
  waf_rate_limit    = 5000
  enable_api_key    = true
  rate_limit        = 100
  burst_limit       = 200
  
  # Monitoring Configuration
  enable_monitoring = true
  log_retention_days = 30
  alarm_actions = [
    "arn:aws:sns:us-east-1:123456789012:alerts-topic"
  ]
  
  tags = {
    Environment = "production"
    Project     = "ai-api"
    Team        = "data-science"
    CostCenter  = "ai-ml"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Prefix for all resource names | `string` | `"bedrock-api"` | no |
| tags | Tags to apply to all resources | `map(string)` | `{"Environment"="production","Project"="bedrock-api","ManagedBy"="terraform"}` | no |
| bedrock_model_id | Amazon Bedrock model ID to use | `string` | `"anthropic.claude-3-sonnet-20240229-v1:0"` | no |
| bedrock_model_arns | List of Bedrock model ARNs that Lambda can access | `list(string)` | `["arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0",...]` | no |
| lambda_runtime | Lambda function runtime | `string` | `"python3.11"` | no |
| lambda_timeout | Lambda function timeout in seconds | `number` | `30` | no |
| lambda_memory_size | Lambda function memory size in MB | `number` | `512` | no |
| log_level | Log level for Lambda function | `string` | `"INFO"` | no |
| log_retention_days | CloudWatch log retention in days | `number` | `14` | no |
| api_stage_name | API Gateway stage name | `string` | `"prod"` | no |
| max_tokens | Maximum number of tokens to generate | `number` | `1000` | no |
| temperature | Temperature for text generation (0.0 to 1.0) | `number` | `0.7` | no |
| top_p | Top-p sampling parameter (0.0 to 1.0) | `number` | `0.9` | no |
| enable_monitoring | Enable CloudWatch monitoring and alarms | `bool` | `true` | no |
| alarm_actions | List of ARNs for CloudWatch alarm actions | `list(string)` | `[]` | no |
| enable_waf | Enable WAF for API Gateway | `bool` | `false` | no |
| waf_rate_limit | WAF rate limit per 5 minutes | `number` | `2000` | no |
| enable_cors | Enable CORS for API Gateway | `bool` | `true` | no |
| cors_allowed_origins | List of allowed origins for CORS | `list(string)` | `["*"]` | no |
| cors_allowed_methods | List of allowed HTTP methods for CORS | `list(string)` | `["GET","POST","OPTIONS"]` | no |
| cors_allowed_headers | List of allowed headers for CORS | `list(string)` | `["Content-Type","Authorization","X-Requested-With"]` | no |
| enable_api_key | Enable API key authentication | `bool` | `false` | no |
| api_key_name | Name for the API key | `string` | `"bedrock-api-key"` | no |
| usage_plan_name | Name for the usage plan | `string` | `"bedrock-usage-plan"` | no |
| rate_limit | API Gateway rate limit per second | `number` | `10` | no |
| burst_limit | API Gateway burst limit | `number` | `20` | no |

## Outputs

| Name | Description |
|------|-------------|
| api_gateway_url | URL of the API Gateway endpoint |
| api_gateway_rest_api_id | ID of the API Gateway REST API |
| api_gateway_stage_name | Name of the API Gateway stage |
| lambda_function_name | Name of the Lambda function |
| lambda_function_arn | ARN of the Lambda function |
| lambda_function_invoke_arn | Invocation ARN of the Lambda function |
| lambda_role_arn | ARN of the Lambda execution role |
| lambda_role_name | Name of the Lambda execution role |
| cloudwatch_log_group_name | Name of the CloudWatch log group |
| cloudwatch_log_group_arn | ARN of the CloudWatch log group |
| bedrock_policy_arn | ARN of the Bedrock access policy |
| waf_web_acl_arn | ARN of the WAF Web ACL (if enabled) |
| waf_web_acl_id | ID of the WAF Web ACL (if enabled) |
| cloudwatch_alarm_names | Names of CloudWatch alarms (if monitoring enabled) |
| api_key_id | ID of the API Gateway API key (if enabled) |
| api_key_value | Value of the API Gateway API key (if enabled) |
| usage_plan_id | ID of the API Gateway usage plan (if enabled) |
| rate_limit | API Gateway rate limit per second |
| burst_limit | API Gateway burst limit |
| module_version | Version of this Terraform module |
| bedrock_model_id | Bedrock model ID being used |
| lambda_runtime | Lambda runtime being used |
| lambda_timeout | Lambda timeout in seconds |
| lambda_memory_size | Lambda memory size in MB |
| api_gateway_execution_arn | Execution ARN of the API Gateway |
| tags | Tags applied to all resources |

## API Usage

### Request Format

```json
{
  "prompt": "Your text prompt here",
  "max_tokens": 1000,
  "temperature": 0.7,
  "top_p": 0.9
}
```

### Response Format

```json
{
  "success": true,
  "content": "Generated text response from the model",
  "model_id": "anthropic.claude-3-sonnet-20240229-v1:0",
  "usage": {
    "input_tokens": 10,
    "output_tokens": 50
  },
  "metadata": {
    "execution_time_ms": 1250.5,
    "timestamp": 1640995200,
    "request_id": "abc123-def456"
  }
}
```

### Example cURL Request

```bash
# Basic request
curl -X POST https://your-api-gateway-url.amazonaws.com/prod/bedrock \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Explain quantum computing in simple terms",
    "max_tokens": 500,
    "temperature": 0.7
  }'

# With API key (if enabled)
curl -X POST https://your-api-gateway-url.amazonaws.com/prod/bedrock \
  -H "Content-Type: application/json" \
  -H "x-api-key: your-api-key-here" \
  -d '{
    "prompt": "Explain quantum computing in simple terms",
    "max_tokens": 500,
    "temperature": 0.7
  }'
```

## Supported Bedrock Models

The module supports various Bedrock models including:

- **Anthropic Claude**: `anthropic.claude-3-sonnet-20240229-v1:0`, `anthropic.claude-3-haiku-20240307-v1:0`
- **Amazon Titan**: `amazon.titan-text-express-v1`, `amazon.titan-text-lite-v1`
- **AI21 Jurassic**: `ai21.j2-ultra-v1`, `ai21.j2-mid-v1`
- **Cohere Command**: `cohere.command-text-v14`, `cohere.command-light-text-v14`
- **Meta Llama**: `meta.llama2-13b-chat-v1`, `meta.llama2-70b-chat-v1`

## Security Considerations

1. **IAM Roles**: The module creates least-privilege IAM roles for Lambda
2. **WAF Protection**: Optional WAF with rate limiting and AWS managed rules
3. **API Key Authentication**: Optional API key-based authentication
4. **CORS Configuration**: Configurable CORS settings for web applications
5. **Logging**: Comprehensive CloudWatch logging for audit trails

## Monitoring and Alerting

The module includes:

- **CloudWatch Alarms**: Lambda errors and duration monitoring
- **Log Retention**: Configurable log retention periods
- **Custom Metrics**: Execution time and request tracking
- **Alarm Actions**: Integration with SNS topics for notifications

## Cost Optimization

- **Lambda Configuration**: Optimize memory and timeout settings
- **Log Retention**: Reduce log retention for non-production environments
- **WAF**: Only enable WAF when needed for production workloads
- **API Key**: Use API keys to control and monitor usage

## Troubleshooting

### Common Issues

1. **Bedrock Access Denied**: Ensure Bedrock is enabled in your AWS region
2. **Lambda Timeout**: Increase `lambda_timeout` for complex prompts
3. **Memory Issues**: Increase `lambda_memory_size` for large responses
4. **CORS Errors**: Verify `cors_allowed_origins` includes your domain

### Debugging

1. Check CloudWatch logs for Lambda function errors
2. Verify API Gateway logs for request/response issues
3. Test Bedrock access directly using AWS CLI
4. Validate IAM permissions for all services

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This module is licensed under the MIT License. See the LICENSE file for details.

## Support

For issues and questions:
- Create an issue in the repository
- Check the troubleshooting section
- Review AWS documentation for Bedrock, Lambda, and API Gateway