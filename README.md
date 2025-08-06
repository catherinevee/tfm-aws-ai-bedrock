# Terraform AWS Bedrock Module

Terraform infrastructure for exposing Amazon Bedrock models through a Lambda-backed REST API. Sets up the full request pipeline from API Gateway to Bedrock, with optional WAF protection and monitoring.

## Architecture

![Architecture](docs/architecture.png)

### Request Flow

Client → API Gateway → Lambda → Bedrock → Response back through stack

CloudWatch captures all execution logs. WAF blocks malicious requests when enabled.

## Resources Created

| Category | Resource | Purpose |
|----------|----------|---------|
| Compute  | `aws_lambda_function` | Handles Bedrock API calls and response formatting |
| API      | `aws_api_gateway_rest_api` | Exposes HTTP endpoint for model inference |
| API      | `aws_api_gateway_stage` | Manages deployment stages (prod, dev, staging) |
| IAM      | `aws_iam_role` | Lambda execution role with minimal Bedrock permissions |
| IAM      | `aws_iam_role_policy` | Bedrock model access and CloudWatch logging |
| Logs     | `aws_cloudwatch_log_group` | Lambda execution and error logs |
| Security | `aws_wafv2_web_acl` | Rate limiting and basic attack protection |
| Monitor  | `aws_cloudwatch_metric_alarm` | Lambda error and duration alerts |

## What You Get

- **Model Access**: Direct HTTP API to any Bedrock model 
- **Auto-scaling**: Lambda handles concurrent requests without configuration
- **Request Validation**: Input sanitization and error handling
- **CORS Support**: Ready for web application integration  
- **Rate Limiting**: Configurable throttling via API Gateway and WAF
- **Monitoring**: CloudWatch alarms for errors and performance issues

## Before You Start

- Terraform >= 1.0
- AWS CLI with proper credentials configured
- Bedrock model access enabled in your target region
- IAM permissions for Lambda, API Gateway, and Bedrock services

## Quick Start

```hcl
module "bedrock_api" {
  source = "terraform-aws-bedrock"

  name_prefix      = "my-ai-api"
  bedrock_model_id = "anthropic.claude-3-sonnet-20240229-v1:0"
  
  tags = {
    Environment = "production"
    Project     = "ai-services"
  }

  # Optional: Add WAF protection for production
  enable_waf     = true
  waf_rate_limit = 1000
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

## Troubleshooting

### Lambda Timeouts
Increase `lambda_timeout` for complex prompts. Max is 900 seconds.
```hcl
lambda_timeout = 60  # seconds
```

### Rate Limiting Issues
API Gateway returns 429 errors when limits are exceeded. Adjust WAF settings:
```hcl
enable_waf     = true
waf_rate_limit = 2000  # requests per 5 minutes
```

### VPC Connectivity Problems
Lambda needs internet access to reach Bedrock. Ensure NAT Gateway exists and security groups allow outbound HTTPS.

### Missing Logs
Verify IAM permissions include `logs:CreateLogGroup` and `logs:PutLogEvents`. Check `log_level` variable setting.

### Authentication Failures
When using API keys, verify token format and that usage plan is attached correctly.

## IAM Permissions Needed

The deploying user needs these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:AttachRolePolicy", 
        "lambda:CreateFunction",
        "apigateway:*",
        "logs:CreateLogGroup",
        "bedrock:InvokeModel"
      ],
      "Resource": "*"
    }
  ]
}
```

## Examples

### Basic Setup
```hcl
module "bedrock_api" {
  source = "./tfm-aws-ai-bedrock"

  name_prefix = "my-ai-api"
  
  tags = {
    Environment = "production"
    Project     = "ai-api"
  }
}
```

### Production Configuration
```hcl
module "bedrock_api" {
  source = "./tfm-aws-ai-bedrock"

  name_prefix      = "prod-ai-api"
  bedrock_model_id = "anthropic.claude-3-sonnet-20240229-v1:0"
  
  # Lambda settings
  lambda_timeout     = 60
  lambda_memory_size = 1024
  
  # Security
  enable_waf     = true
  waf_rate_limit = 5000
  enable_api_key = true
  
  # CORS for web apps  
  cors_allowed_origins = ["https://myapp.com"]
  
  tags = {
    Environment = "production"
    Project     = "ai-api"
    CostCenter  = "ml-team"
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

Send POST requests to `{api_gateway_url}/bedrock`:

```json
{
  "prompt": "Explain quantum computing",
  "max_tokens": 1000,
  "temperature": 0.7
}
```

### Response Format

```json
{
  "success": true,
  "content": "Quantum computing uses quantum mechanics...",
  "model_id": "anthropic.claude-3-sonnet-20240229-v1:0",
  "usage": {
    "input_tokens": 10,
    "output_tokens": 50
  }
}
```

### cURL Example

```bash
curl -X POST https://your-api.amazonaws.com/prod/bedrock \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Hello world", "max_tokens": 100}'
```

## Supported Models

Compatible with all Bedrock foundation models:
- **Anthropic Claude**: `anthropic.claude-3-sonnet-20240229-v1:0`, `anthropic.claude-3-haiku-20240307-v1:0`
- **Amazon Titan**: `amazon.titan-text-express-v1`, `amazon.titan-text-lite-v1` 
- **AI21 Jurassic**: `ai21.j2-ultra-v1`, `ai21.j2-mid-v1`
- **Meta Llama**: `meta.llama2-13b-chat-v1`, `meta.llama2-70b-chat-v1`

Check AWS docs for the latest model IDs available in your region.

## Implementation Notes

**Security**: Module creates minimal IAM permissions. WAF provides basic DDoS protection but doesn't replace proper API design.

**Performance**: Lambda cold starts add ~1-2 seconds to first requests. Consider provisioned concurrency for latency-sensitive applications.

**Cost**: Bedrock charges per token. Monitor usage via CloudWatch metrics to avoid surprises.

**Reliability**: No built-in retry logic for Bedrock API calls. Consider implementing client-side retries for production use.

## State Management

For production deployments, use remote state storage:

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-states"
    key    = "bedrock-api/terraform.tfstate"
    region = "us-east-1"
  }
}
```

## License

Apache 2.0 Licensed. See [LICENSE](LICENSE) for details.