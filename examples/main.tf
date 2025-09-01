module "vpc" {
  source = "../../terraform-aws-vpc" 
  name               = "example-vpc"
  availability_zones = ["us-east-1a", "us-east-1b"]
  enable_flow_logs   = true

  tags = {
    Name        = "example-vpc"
    Environment = "development"
    Project     = "vpc-module-testing"
    ManagedBy   = "Terraform"
  }
}

module "kms_key_for_logs" {
  source = "../../terraform-aws-kms"
  key_description      = "KMS key for VPC flow logs encryption"
  alias_name           = "alias/vpc-flow-logs"
  tags = {
    Name = "kms-vpc-flow-logs"
  }
}