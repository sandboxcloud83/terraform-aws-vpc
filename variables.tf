variable "name" {
  description = "The name for the VPC and its resources. This will be used as a prefix."
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}

variable "cidr_block" {
  description = "The main IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "A list of Availability Zones to use for the subnets (e.g., [\"us-east-1a\", \"us-east-1b\"])."
  type        = list(string)
}

variable "public_subnets_cidrs" {
  description = "A list of IPv4 CIDR blocks for the public subnets. Must have the same number of elements as availability_zones."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets_cidrs" {
  description = "A list of IPv4 CIDR blocks for the private subnets. Must have the same number of elements as availability_zones."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "enable_nat_gateway" {
  description = "Set to true to create NAT Gateways for the private subnets. This will incur costs."
  type        = bool
  default     = true
}

variable "map_public_ip_on_launch" {
  description = "Set to true to assign a public IP address to instances launched in public subnets."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Set to true to enable VPC Flow Logs to be sent to CloudWatch."
  type        = bool
  default     = false
}

variable "flow_logs_kms_key_arn" {
  description = "Optional KMS Key ARN to encrypt the CloudWatch Log Group for VPC Flow Logs."
  type        = string
  default     = null
}
