# Terraform AWS VPC Module

A foundational Terraform module for creating a robust and secure Virtual Private Cloud (VPC) on Amazon Web Services (AWS).

This module is designed following industry best practices to provide a flexible and secure network backbone for your AWS workloads. It handles the creation of the VPC, subnets across multiple Availability Zones, routing, and optional security features like VPC Flow Logs with KMS encryption.

---
## Features

- Creates a VPC with a configurable CIDR block.
- Manages Public and Private subnets across a configurable list of Availability Zones.
- **Conditional NAT Gateways**: Creates NAT Gateways for outbound traffic from private subnets (can be disabled to save costs).
- **Conditional VPC Flow Logs**: Optionally enables VPC Flow Logs to a CloudWatch Log Group for network traffic monitoring.
- **KMS Encryption**: Optionally encrypts the Flow Logs CloudWatch Log Group with a customer-managed KMS key.
- **Configurable IP Mapping**: Controls the automatic assignment of public IPs in public subnets.
- Follows a "pass-through" tagging strategy for all resources.



---
## Usage

Here is a basic example of how to use the module to create a VPC with public and private subnets.

```terraform
module "vpc" {
  source = "[github.com/](https://github.com/)<TU_USUARIO>/terraform-aws-vpc?ref=v1.0.0"

  name               = "my-app-vpc"
  availability_zones = ["us-east-1a", "us-east-1b"]

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

---
## Examples

For more detailed use cases, please refer to the `examples/` directory:

- **[simple-vpc](./examples/simple-vpc)**: Shows the basic module usage and integration with the KMS module for Flow Log encryption.

---
## Requirements

| Name | Version |
| :--- | :--- |
| terraform | >= 1.0 |
| aws | ~> 5.0 |

---
## Inputs

| Name | Description | Type | Default | Required |
| :--- | :--- | :--- | :--- | :---: |
| `name` | The name for the VPC and its resources. This will be used as a prefix. | `string` | `null` | yes |
| `availability_zones` | A list of Availability Zones to use for the subnets (e.g., `["us-east-1a"]`). | `list(string)` | `null` | yes |
| `cidr_block` | The main IPv4 CIDR block for the VPC. | `string` | `"10.0.0.0/16"` | no |
| `public_subnets_cidrs` | A list of IPv4 CIDR blocks for the public subnets. Must match the length of `availability_zones`. | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24"]` | no |
| `private_subnets_cidrs` | A list of IPv4 CIDR blocks for the private subnets. Must match the length of `availability_zones`. | `list(string)` | `["10.0.101.0/24", "10.0.102.0/24"]` | no |
| `tags` | A map of tags to add to all resources. | `map(string)` | `{}` | no |
| `enable_nat_gateway` | Set to `true` to create NAT Gateways for the private subnets. This will incur costs. | `bool` | `true` | no |
| `map_public_ip_on_launch` | Set to `true` to assign a public IP address to instances launched in public subnets. | `bool` | `true` | no |
| `enable_flow_logs` | Set to `true` to enable VPC Flow Logs to be sent to CloudWatch. | `bool` | `false` | no |
| `flow_logs_kms_key_arn` | Optional KMS Key ARN to encrypt the CloudWatch Log Group for VPC Flow Logs. | `string` | `null` | no |

---
## Outputs

| Name | Description |
| :--- | :--- |
| `vpc_id` | The ID of the created VPC. |
| `public_subnet_ids` | A list of the IDs of the public subnets. |
| `private_subnet_ids` | A list of the IDs of the private subnets. |

---
## License

This module is licensed under the Mozilla Public License 2.0. See the `LICENSE` file for more details.