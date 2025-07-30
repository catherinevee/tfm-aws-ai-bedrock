# Makefile for Amazon Bedrock + Lambda + API Gateway Terraform Module

.PHONY: help init plan apply destroy validate fmt lint clean test docs

# Default target
help:
	@echo "Available commands:"
	@echo "  init      - Initialize Terraform"
	@echo "  plan      - Plan Terraform changes"
	@echo "  apply     - Apply Terraform changes"
	@echo "  destroy   - Destroy Terraform resources"
	@echo "  validate  - Validate Terraform configuration"
	@echo "  fmt       - Format Terraform code"
	@echo "  lint      - Lint Terraform code"
	@echo "  clean     - Clean up temporary files"
	@echo "  test      - Run tests"
	@echo "  docs      - Generate documentation"

# Initialize Terraform
init:
	terraform init

# Plan Terraform changes
plan:
	terraform plan -out=tfplan

# Apply Terraform changes
apply:
	terraform apply tfplan

# Destroy Terraform resources
destroy:
	terraform destroy

# Validate Terraform configuration
validate:
	terraform validate

# Format Terraform code
fmt:
	terraform fmt -recursive

# Lint Terraform code (requires tflint)
lint:
	@if command -v tflint >/dev/null 2>&1; then \
		tflint; \
	else \
		echo "tflint not found. Install with: go install github.com/terraform-linters/tflint/cmd/tflint@latest"; \
	fi

# Clean up temporary files
clean:
	rm -f tfplan
	rm -f *.tfstate.backup
	rm -f lambda_function.zip
	find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true

# Run tests (placeholder for future test implementation)
test:
	@echo "Running tests..."
	@echo "Tests not implemented yet. Consider adding terratest or similar."

# Generate documentation
docs:
	@echo "Generating documentation..."
	@if command -v terraform-docs >/dev/null 2>&1; then \
		terraform-docs markdown table . > README.md.tmp && \
		mv README.md.tmp README.md; \
	else \
		echo "terraform-docs not found. Install with: go install github.com/terraform-docs/terraform-docs/cmd/terraform-docs@latest"; \
	fi

# Check for security issues (requires tfsec)
security:
	@if command -v tfsec >/dev/null 2>&1; then \
		tfsec .; \
	else \
		echo "tfsec not found. Install with: go install github.com/aquasecurity/tfsec/cmd/tfsec@latest"; \
	fi

# Full validation pipeline
check: fmt validate lint security
	@echo "All checks passed!"

# Deploy to development environment
deploy-dev:
	@echo "Deploying to development environment..."
	terraform workspace select dev || terraform workspace new dev
	terraform plan -var-file=dev.tfvars -out=tfplan
	terraform apply tfplan

# Deploy to production environment
deploy-prod:
	@echo "Deploying to production environment..."
	terraform workspace select prod || terraform workspace new prod
	terraform plan -var-file=prod.tfvars -out=tfplan
	terraform apply tfplan

# Show current workspace
workspace:
	terraform workspace show

# List all workspaces
workspace-list:
	terraform workspace list

# Output module information
output:
	terraform output

# Show resources
show:
	terraform show

# Refresh state
refresh:
	terraform refresh

# Import existing resources (example)
import-example:
	@echo "Example import command:"
	@echo "terraform import module.bedrock_api.aws_lambda_function.bedrock_lambda function-name"

# Cost estimation (requires infracost)
cost:
	@if command -v infracost >/dev/null 2>&1; then \
		infracost breakdown --path .; \
	else \
		echo "infracost not found. Install with: curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh"; \
	fi

# Update dependencies
update-deps:
	terraform init -upgrade

# Lock provider versions
lock-providers:
	terraform providers lock -platform=linux_amd64 -platform=darwin_amd64 -platform=windows_amd64

# Create example configuration
create-example:
	@echo "Creating example configuration..."
	@mkdir -p examples/my-example
	@cp examples/basic/main.tf examples/my-example/
	@echo "Example created in examples/my-example/"

# Backup state
backup:
	@if [ -f terraform.tfstate ]; then \
		cp terraform.tfstate terraform.tfstate.backup.$$(date +%Y%m%d_%H%M%S); \
		echo "State backed up"; \
	else \
		echo "No terraform.tfstate found"; \
	fi

# Restore state from backup
restore:
	@ls -la terraform.tfstate.backup.* 2>/dev/null || echo "No backups found"
	@echo "To restore, run: cp terraform.tfstate.backup.YYYYMMDD_HHMMSS terraform.tfstate" 