package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformBedrockModule(t *testing.T) {
	t.Parallel()

	// Generate a random name prefix to avoid conflicts
	uniqueID := random.UniqueId()
	namePrefix := fmt.Sprintf("bedrock-test-%s", uniqueID)

	// Terraform options for testing
	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/basic",
		Vars: map[string]interface{}{
			"name_prefix":      namePrefix,
			"environment":      "dev",
			"bedrock_model_id": "anthropic.claude-3-sonnet-20240229-v1:0",
		},
	}

	// Clean up resources when the test is finished
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Test outputs
	apiEndpoint := terraform.Output(t, terraformOptions, "api_endpoint")
	assert.NotEmpty(t, apiEndpoint, "API endpoint should not be empty")

	// Test API functionality
	maxRetries := 3
	timeBetweenRetries := 10 * time.Second
	url := fmt.Sprintf("%s/test", apiEndpoint)

	// Test request body
	requestBody := `{
		"prompt": "Hello, world!",
		"max_tokens": 100
	}`

	// Test API response
	statusCode, body := http_helper.HTTPDoWithRetryE(t, "POST", url, []byte(requestBody), nil, 200, maxRetries, timeBetweenRetries)

	// Verify response
	assert.Equal(t, 200, statusCode, "Expected HTTP status code 200")
	assert.Contains(t, string(body), "completion", "Response should contain completion field")

	// Test CloudWatch Logs
	logGroup := terraform.Output(t, terraformOptions, "cloudwatch_log_group_name")
	assert.NotEmpty(t, logGroup, "CloudWatch log group name should not be empty")

	// Test Lambda function
	lambdaArn := terraform.Output(t, terraformOptions, "lambda_function_arn")
	assert.NotEmpty(t, lambdaArn, "Lambda function ARN should not be empty")

	// Test WAF if enabled
	wafEnabled := terraform.Output(t, terraformOptions, "waf_enabled")
	if wafEnabled == "true" {
		wafArn := terraform.Output(t, terraformOptions, "waf_web_acl_arn")
		assert.NotEmpty(t, wafArn, "WAF Web ACL ARN should not be empty when WAF is enabled")
	}
}
