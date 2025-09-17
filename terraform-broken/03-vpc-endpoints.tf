# VPC Endpoints for ECS Container Image Operations

# ECR API Interface Endpoint - For ECR API calls
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = data.aws_vpc.main.id
  service_name        = "com.amazonaws.us-west-2.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.private.ids
  security_group_ids  = [data.aws_security_group.app.id]
  private_dns_enabled = true

  tags = {
    Name         = "${var.PrefixCode}-vpce-ecr-api"
    resourcetype = "network"
    codeblock    = "vpc-endpoints"
  }
}

# ECR DKR Interface Endpoint - For Docker registry operations
resource "aws_vpc_endpoint" "ecr_dkr" {
  # TODO: Complete this resource block
  # HINT: Very similar to the first block, but with different service_name
}