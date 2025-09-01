# ---------------------------------------------------------------------------------------------------------------------
# VPC Resource
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = var.tags
}

# ---------------------------------------------------------------------------------------------------------------------
# Subnets
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_subnet" "public" {
  # Create one public subnet for each CIDR block provided.
  count = length(var.public_subnets_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  # trivy:ignore:AVD-AWS-0164[I am creating a public subnet, this is intentional]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = var.tags
}

resource "aws_subnet" "private" {
  # Create one private subnet for each CIDR block provided.
  count = length(var.private_subnets_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = var.tags
}

# ---------------------------------------------------------------------------------------------------------------------
# Internet Gateway & Public Routing
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = var.tags
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    # Route for outbound internet traffic.
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = var.tags
}

resource "aws_route_table_association" "public" {
  # Associate the public route table with each public subnet.
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------------------------------------------------------------
# NAT Gateway & Private Routing (Conditional)
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_eip" "nat" {
  # Create one Elastic IP for each NAT Gateway. Only created if NAT Gateways are enabled.
  count = var.enable_nat_gateway ? length(var.private_subnets_cidrs) : 0
  
  domain = "vpc" # This argument is deprecated and will be removed in a future version.
                 # It's kept here for compatibility with older AWS provider versions.
                 # For provider v5+ this is effectively ignored.
  tags = var.tags
}


resource "aws_nat_gateway" "this" {
  # Create one NAT Gateway in each public subnet. Only created if NAT Gateways are enabled.
  count = var.enable_nat_gateway ? length(var.private_subnets_cidrs) : 0

  allocation_id = aws_eip.nat[count.index].id
  # A NAT Gateway must reside in a public subnet.
  subnet_id = aws_subnet.public[count.index].id

  tags = var.tags

  # Explicit dependency to ensure the IGW is created before the NAT Gateway.
  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  # Create one private route table for each private subnet. Only created if NAT Gateways are enabled.
  count = var.enable_nat_gateway ? length(var.private_subnets_cidrs) : 0

  vpc_id = aws_vpc.this.id

  route {
    # Route for outbound internet traffic via the NAT Gateway.
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }

  tags = var.tags
}

resource "aws_route_table_association" "private" {
  # Associate each private route table with its corresponding private subnet.
  count = var.enable_nat_gateway ? length(var.private_subnets_cidrs) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# In main.tf, at the end of the file

# ---------------------------------------------------------------------------------------------------------------------
# VPC Flow Logs (Conditional)
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "flow_logs" {
  # Create only if flow logs are enabled
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpcflow/${var.name}"
  retention_in_days = 14 # Or make this configurable
  kms_key_id        = var.flow_logs_kms_key_arn
  tags = var.tags
}

resource "aws_iam_role" "flow_logs" {
  # Create only if flow logs are enabled
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.name}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  # Create only if flow logs are enabled
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.name}-flow-logs-policy"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = aws_cloudwatch_log_group.flow_logs[0].arn
      }
    ]
  })
}

resource "aws_flow_log" "this" {
  # Create only if flow logs are enabled
  count = var.enable_flow_logs ? 1 : 0

  vpc_id         = aws_vpc.this.id
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flow_logs[0].arn
  iam_role_arn   = aws_iam_role.flow_logs[0].arn
  traffic_type   = "ALL"

  tags = var.tags
}
