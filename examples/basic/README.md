# Basic Example

This example demonstrates a basic usage of the AWS Bedrock API module.

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Note that this example may create resources which cost money. Run `terraform destroy` when you don't need these resources.

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.13.0 |
| aws | ~> 6.2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 6.2.0 |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| api_url | The URL of the API Gateway endpoint |
