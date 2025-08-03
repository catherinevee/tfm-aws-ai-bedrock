# Changelog

All notable changes to this module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-08-02

### Added
- Support for Claude 3 models (Sonnet and Haiku)
- WAF integration for API protection
- Automated testing with native Terraform tests
- Comprehensive module documentation
- Resource map in README

### Changed
- Updated AWS provider version to 6.2.0
- Updated Terraform version requirement to 1.13.0
- Updated Azure provider version to 4.38.1
- Improved variable validations
- Enhanced security configurations

### Fixed
- IAM policy permissions for Bedrock access
- API Gateway CORS handling
- CloudWatch log retention configuration

## [1.0.0] - 2024-12-15

### Added
- Initial release with basic Bedrock API functionality
- Lambda function integration
- API Gateway setup
- Basic monitoring and logging
- Example configurations

[2.0.0]: https://github.com/catherinevee/tfm-aws-ai-bedrock/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/catherinevee/tfm-aws-ai-bedrock/releases/tag/v1.0.0
