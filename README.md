# Terraform AWS Bedrock Module

A comprehensive Terraform module for deploying a serverless AI solution using Amazon Bedrock, AWS Lambda, and API Gateway. This module provides a complete infrastructure setup for creating AI-powered APIs with enterprise-grade features including monitoring, security, and scalability.

## Resource Map

![Architecture](docs/architecture.png)

### Resource Flow

1. Client sends request to API Gateway
2. API Gateway forwards request to Lambda
3. Lambda function calls Bedrock API
4. Bedrock returns AI model response
5. Response flows back through Lambda and API Gateway
6. CloudWatch logs all operations
7. WAF (optional) protects the API

## Resource Types Used

This module creates and manages the following AWS resources:

| Category | Resource Type | Description |
|----------|--------------|-------------|
| Compute  | `aws_lambda_function` | Python Lambda function for Bedrock integration |
| API      | `aws_api_gateway_rest_api` | REST API for model inference |
| API      | `aws_api_gateway_stage` | API deployment stage (prod, dev) |
| API      | `aws_api_gateway_method` | HTTP method configurations |
| API      | `aws_api_gateway_integration` | Lambda integration settings |
| IAM      | `aws_iam_role` | Execution role for Lambda |
| IAM      | `aws_iam_role_policy` | Bedrock access permissions |
| Logs     | `aws_cloudwatch_log_group` | Lambda function logs |
| Security | `aws_wafv2_web_acl` (Optional) | WAF protection for API |
| Monitoring | `aws_cloudwatch_metric_alarm` | Resource monitoring |

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

## Usage

```hcl
module "bedrock_api" {
  source = "terraform-aws-bedrock"

  name_prefix     = "my-ai-api"
  bedrock_model_id = "anthropic.claude-3-sonnet-20240229-v1:0"
  
  tags = {
    Environment = "production"
    Project     = "ai-services"
  }

  # Optional: Enable WAF protection
  enable_waf = true
  waf_rate_limit = 1000

  # Optional: Configure monitoring
  enable_monitoring = true
  error_rate_threshold = 1.0
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.13.0 |
| aws | ~> 6.2.0 |
| archive | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 6.2.0 |
| archive | ~> 2.0 |

## Upgrading

### Upgrading to v1.x

1. Update your provider versions:
   ```hcl
   terraform {
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = "~> 6.2.0"
       }
     }
     required_version = "~> 1.13.0"
   }
   ```

2. If using VPC configuration:
   ```hcl
   module "bedrock_api" {
     vpc_subnet_ids         = ["subnet-xxx", "subnet-yyy"]
     vpc_security_group_ids = ["sg-zzz"]
   }
   ```

3. For enhanced security:
   ```hcl
   module "bedrock_api" {
     enable_cloudwatch_logs_encryption = true
     enable_xray_tracing              = true
     enable_waf                       = true
   }
   ```

4. For multi-region deployment:
   - See examples/advanced for complete configuration

### Breaking Changes in v1.0.0

- Removed Azure provider dependency
- Changed Lambda artifact storage to S3
- Updated WAF configuration format
- Added required tags validation

## Troubleshooting Guide

### Common Issues

1. **Lambda Function Timeout**
   - **Symptom**: Lambda function execution timeouts
   - **Solution**: Increase `lambda_timeout` variable (max 900 seconds)
   - **Example**:
     ```hcl
     module "bedrock_api" {
       lambda_timeout = 60
     }
     ```

2. **API Gateway 429 Errors**
   - **Symptom**: Too many requests errors
   - **Solution**: Adjust WAF rate limits
   - **Example**:
     ```hcl
     module "bedrock_api" {
       enable_waf     = true
       waf_rate_limit = 2000
     }
     ```

3. **VPC Connectivity Issues**
   - **Symptom**: Lambda cannot access Bedrock API
   - **Solution**: Ensure NAT Gateway/Instance is configured
   - **Check**: Verify security group outbound rules

4. **CloudWatch Logs Missing**
   - **Symptom**: No Lambda logs in CloudWatch
   - **Solution**: Check IAM permissions and log settings
   - **Verify**: `log_level` variable configuration

5. **Cognito Authentication Errors**
   - **Symptom**: API returns 401/403 errors
   - **Solution**: Verify Cognito pool configuration
   - **Check**: Token format and expiration

### Performance Optimization

1. **Lambda Performance**
   - Use ARM64 architecture for better price/performance
   - Adjust memory allocation based on workload
   - Enable X-Ray for tracing

2. **API Gateway Latency**
   - Enable caching for repeated requests
   - Use regional endpoints
   - Monitor and adjust throttling

3. **Cost Management**
   - Enable detailed CloudWatch metrics
   - Set up cost allocation tags
   - Monitor API usage patterns

## Required AWS Permissions

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

## Best Practices Implemented

1. **Security**
   - WAF protection (optional)
   - API key authentication
   - Least privilege IAM roles
   - VPC isolation support
   - CloudWatch logging

2. **Performance**
   - Configurable Lambda settings
   - Response caching support
   - Efficient token usage
   - Request batching capability

3. **Reliability**
   - Automatic retries
   - Circuit breaker pattern
   - Error handling
   - Fallback models

4. **Cost Optimization**
   - Configurable rate limits
   - Token usage monitoring
   - Resource tagging
   - Cost allocation support

5. **Operational Excellence**
   - Comprehensive monitoring
   - Detailed logging
   - Alarm configuration
   - Performance metrics

## Terraform State Management

This module is designed to work with both local and remote state. For production use, we recommend:

1. Use remote state storage (e.g., S3 + DynamoDB)
2. Enable state locking
3. Enable state encryption
4. Use workspaces for multi-environment management

Example backend configuration:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-states"
    key            = "bedrock-api/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

## Upgrade Guide

### Upgrading from v1.x to v2.x

1. Update your module source to reference v2.x
2. Review the breaking changes in CHANGELOG.md
3. Update your variable declarations as needed
4. Run `terraform init -upgrade`
5. Review the plan before applying

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes with conventional commits
4. Update documentation and examples
5. Submit a pull request

## Authors

Module maintained by:
- Your Organization (@github-handle)
- Contributors List

## License

Apache 2.0 Licensed. See [LICENSE](LICENSE) for full details.

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