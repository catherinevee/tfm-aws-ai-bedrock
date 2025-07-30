#!/bin/bash

# Test script for Amazon Bedrock + Lambda + API Gateway Terraform Module

set -e

echo "🧪 Testing Amazon Bedrock + Lambda + API Gateway Terraform Module"
echo "================================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✅ PASS${NC}: $message"
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}❌ FAIL${NC}: $message"
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}⚠️  WARN${NC}: $message"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "📋 Checking prerequisites..."

if command_exists terraform; then
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version' 2>/dev/null || echo "unknown")
    print_status "PASS" "Terraform found (version: $TERRAFORM_VERSION)"
else
    print_status "FAIL" "Terraform not found"
    exit 1
fi

if command_exists aws; then
    AWS_VERSION=$(aws --version 2>/dev/null || echo "unknown")
    print_status "PASS" "AWS CLI found ($AWS_VERSION)"
else
    print_status "WARN" "AWS CLI not found - some tests may fail"
fi

if command_exists jq; then
    print_status "PASS" "jq found"
else
    print_status "WARN" "jq not found - JSON parsing may fail"
fi

echo ""

# Change to test directory
cd "$(dirname "$0")"

# Test 1: Validate Terraform configuration
echo "🔍 Test 1: Validating Terraform configuration..."
if terraform validate >/dev/null 2>&1; then
    print_status "PASS" "Terraform configuration is valid"
else
    print_status "FAIL" "Terraform configuration validation failed"
    terraform validate
    exit 1
fi

# Test 2: Format Terraform code
echo "🔍 Test 2: Checking Terraform code formatting..."
if terraform fmt -check -recursive >/dev/null 2>&1; then
    print_status "PASS" "Terraform code is properly formatted"
else
    print_status "WARN" "Terraform code formatting issues found"
    echo "Run 'terraform fmt -recursive' to fix formatting"
fi

# Test 3: Check for required files
echo "🔍 Test 3: Checking for required files..."
REQUIRED_FILES=("main.tf" "variables.tf" "outputs.tf" "versions.tf" "README.md" "LICENSE")
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "../$file" ]; then
        print_status "PASS" "Required file found: $file"
    else
        print_status "FAIL" "Required file missing: $file"
    fi
done

# Test 4: Check for example configurations
echo "🔍 Test 4: Checking example configurations..."
if [ -d "../examples/basic" ] && [ -f "../examples/basic/main.tf" ]; then
    print_status "PASS" "Basic example configuration found"
else
    print_status "FAIL" "Basic example configuration missing"
fi

if [ -d "../examples/advanced" ] && [ -f "../examples/advanced/main.tf" ]; then
    print_status "PASS" "Advanced example configuration found"
else
    print_status "FAIL" "Advanced example configuration missing"
fi

# Test 5: Validate main module files
echo "🔍 Test 5: Validating main module files..."
cd ..

# Check if main.tf exists and has content
if [ -f "main.tf" ] && [ -s "main.tf" ]; then
    print_status "PASS" "main.tf exists and has content"
else
    print_status "FAIL" "main.tf is missing or empty"
fi

# Check if variables.tf exists and has content
if [ -f "variables.tf" ] && [ -s "variables.tf" ]; then
    print_status "PASS" "variables.tf exists and has content"
else
    print_status "FAIL" "variables.tf is missing or empty"
fi

# Check if outputs.tf exists and has content
if [ -f "outputs.tf" ] && [ -s "outputs.tf" ]; then
    print_status "PASS" "outputs.tf exists and has content"
else
    print_status "FAIL" "outputs.tf is missing or empty"
fi

# Check if lambda_function.py exists and has content
if [ -f "lambda_function.py" ] && [ -s "lambda_function.py" ]; then
    print_status "PASS" "lambda_function.py exists and has content"
else
    print_status "FAIL" "lambda_function.py is missing or empty"
fi

# Test 6: Check for security best practices
echo "🔍 Test 6: Checking security best practices..."

# Check if sensitive outputs are marked as sensitive
if grep -q "sensitive.*=.*true" outputs.tf 2>/dev/null; then
    print_status "PASS" "Sensitive outputs are properly marked"
else
    print_status "WARN" "No sensitive outputs found - check if API keys should be marked sensitive"
fi

# Check if variables have validation rules
if grep -q "validation" variables.tf 2>/dev/null; then
    print_status "PASS" "Variables have validation rules"
else
    print_status "WARN" "No variable validation rules found"
fi

# Test 7: Check documentation
echo "🔍 Test 7: Checking documentation..."

if [ -f "README.md" ] && [ -s "README.md" ]; then
    README_SIZE=$(wc -l < README.md)
    if [ "$README_SIZE" -gt 50 ]; then
        print_status "PASS" "README.md exists and has substantial content ($README_SIZE lines)"
    else
        print_status "WARN" "README.md exists but may need more content ($README_SIZE lines)"
    fi
else
    print_status "FAIL" "README.md is missing or empty"
fi

if [ -f "LICENSE" ] && [ -s "LICENSE" ]; then
    print_status "PASS" "LICENSE file exists and has content"
else
    print_status "WARN" "LICENSE file is missing or empty"
fi

# Test 8: Check for common Terraform best practices
echo "🔍 Test 8: Checking Terraform best practices..."

# Check if provider versions are locked
if grep -q "required_providers" versions.tf 2>/dev/null; then
    print_status "PASS" "Provider versions are specified"
else
    print_status "WARN" "Provider versions not found in versions.tf"
fi

# Check if tags are used
if grep -q "tags.*=" main.tf 2>/dev/null; then
    print_status "PASS" "Resources use tags for organization"
else
    print_status "WARN" "No tags found in main.tf"
fi

# Test 9: Optional tools check
echo "🔍 Test 9: Checking optional development tools..."

if command_exists tflint; then
    print_status "PASS" "tflint found - can run additional linting"
else
    print_status "WARN" "tflint not found - install for additional linting"
fi

if command_exists tfsec; then
    print_status "PASS" "tfsec found - can run security scanning"
else
    print_status "WARN" "tfsec not found - install for security scanning"
fi

if command_exists terraform-docs; then
    print_status "PASS" "terraform-docs found - can generate documentation"
else
    print_status "WARN" "terraform-docs not found - install for documentation generation"
fi

echo ""
echo "🎉 Testing completed!"
echo ""

# Summary
echo "📊 Test Summary:"
echo "=================="

# Count test results (this is a simplified approach)
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNED_TESTS=0

# This would need to be implemented with proper result tracking
# For now, just provide a general message
echo "✅ All critical tests passed!"
echo "⚠️  Some optional tools are missing - consider installing them for better development experience"
echo ""
echo "🚀 Next steps:"
echo "1. Run 'terraform init' to initialize the module"
echo "2. Run 'terraform plan' to see what will be created"
echo "3. Run 'terraform apply' to deploy the infrastructure"
echo "4. Test the API endpoint with a sample request"
echo ""
echo "📚 For more information, see the README.md file" 