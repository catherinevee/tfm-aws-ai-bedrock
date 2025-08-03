package test

import (
	"testing"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestBedrockAPIBasicExample(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/basic",
		Vars: map[string]interface{}{
			"name_prefix": "test-bedrock-api",
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Verify outputs
	apiURL := terraform.Output(t, terraformOptions, "api_url")
	assert.Contains(t, apiURL, "execute-api")

	functionName := terraform.Output(t, terraformOptions, "lambda_function_name")
	assert.Contains(t, functionName, "test-bedrock-api")

	logGroupName := terraform.Output(t, terraformOptions, "cloudwatch_log_group")
	assert.Contains(t, logGroupName, "/aws/lambda/test-bedrock-api")
}
