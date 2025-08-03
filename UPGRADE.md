# Version Upgrade Guide

This guide provides detailed instructions for upgrading between versions of the AWS Bedrock Terraform module.

## Upgrading to v2.0.0 (Future)

### Breaking Changes
- Minimum Terraform version will be 1.14.0
- Minimum AWS provider version will be 6.3.0
- Lambda runtime will default to Python 3.12
- WAF configuration structure will change

### Upgrade Steps
1. Update provider versions
2. Migrate WAF rules
3. Update Lambda configuration
4. Test in non-production environment

## Upgrading to v1.0.0 (Current)

### Breaking Changes
- Removed Azure provider dependency
- Changed Lambda artifact storage to S3
- Updated WAF configuration format
- Added required tags validation
- Changed default Lambda runtime to Python 3.11

### Upgrade Steps

1. Update version constraints:
   ```hcl
   terraform {
     required_version = "~> 1.13.0"
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = "~> 6.2.0"
       }
     }
   }
   ```

2. Remove Azure provider if present:
   ```diff
   - provider "azurerm" {
   -   features {}
   - }
   ```

3. Update module configuration:
   ```hcl
   module "bedrock_api" {
     source = "terraform-aws-bedrock"
     version = "1.0.0"

     # Required configuration
     name_prefix     = "my-ai-api"
     environment     = "prod"  # New required field
     bedrock_model_id = "anthropic.claude-3-sonnet-20240229-v1:0"

     # New configuration options
     enable_cloudwatch_logs_encryption = true
     enable_xray_tracing              = true
     
     tags = {
       Environment = "production"  # Required in v1.0.0
       Project     = "ai-services"
     }
   }
   ```

4. Migrate to S3 artifacts:
   - The module now uses S3 for Lambda artifacts
   - No action required; handled automatically

5. Update WAF rules:
   ```hcl
   module "bedrock_api" {
     enable_waf           = true
     waf_rate_limit      = 1000  # New format
     waf_geo_restrictions = ["US", "CA"]  # New format
   }
   ```

6. Add required tags:
   - Environment tag is now required
   - Project tag is recommended

### Post-Upgrade Actions

1. Run terraform init to download new provider versions
2. Run terraform plan to verify changes
3. Test in non-production environment
4. Update CI/CD pipelines
5. Update documentation references

### Rollback Instructions

If issues occur during upgrade:

1. Revert to previous module version:
   ```hcl
   module "bedrock_api" {
     source  = "terraform-aws-bedrock"
     version = "0.x.x"  # Previous version
   }
   ```

2. Run terraform init and plan/apply

## Upgrading from Pre-Release Versions

If using a pre-release version (0.x.x):

1. Back up your Terraform state
2. Document current configuration
3. Plan for downtime if needed
4. Follow v1.0.0 upgrade steps
5. Test thoroughly in staging

## Need Help?

- Open an issue on GitHub
- Check the troubleshooting guide
- Review example configurations
- Contact support team
