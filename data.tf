# Data sources for AWS Bedrock module

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get available Bedrock models
data "aws_bedrock_model" "selected" {
  model_id = var.bedrock_model_id
}

# KMS key for CloudWatch logs encryption
data "aws_kms_key" "cloudwatch" {
  count = var.enable_cloudwatch_logs_encryption ? 1 : 0
  key_id = var.cloudwatch_kms_key_id != null ? var.cloudwatch_kms_key_id : "alias/aws/lambda"
}

# VPC data if VPC deployment is enabled
data "aws_subnet" "lambda" {
  count = var.vpc_subnet_ids != null ? length(var.vpc_subnet_ids) : 0
  id    = var.vpc_subnet_ids[count.index]
}

data "aws_security_group" "lambda" {
  count = var.vpc_security_group_ids != null ? length(var.vpc_security_group_ids) : 0
  id    = var.vpc_security_group_ids[count.index]
}
