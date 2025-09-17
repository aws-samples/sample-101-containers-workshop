# Application Load Balancer for Application traffic

# Target Group for Frontend Service
resource "aws_lb_target_group" "frontend" {
  name        = "${var.PrefixCode}-targetgroup-ecs"
  port        = 5000
  # checkov:skip=CKV_AWS_378:Target group uses HTTP for workshop environment. Consider end-to-end HTTPS.
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/wildlife/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  ip_address_type = "ipv4"

  tags = {
    Name         = "${var.PrefixCode}-targetgroup-ecs"
    resourcetype = "network"
    codeblock    = "load-balancer"
  }
}

# Application Load Balancer
# nosemgrep: missing-aws-lb-deletion-protection - Deletion protection disabled for development environment to allow easy cleanup
resource "aws_lb" "main" {
  # checkov:skip=CKV2_AWS_28:WAF not implemented for development environment. Consider WAF for production.
  # checkov:skip=CKV2_AWS_20:ALB uses HTTP for workshop environment. Consider end-to-end HTTPS if certificate management overhead is acceptable.
  # checkov:skip=CKV_AWS_150:Deletion protection disabled for development environment to allow easy cleanup
  name               = "${var.PrefixCode}-alb-ecs"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.alb.id]
  subnets            = data.aws_subnets.public.ids
  
  # nosemgrep: missing-aws-lb-deletion-protection - Deletion protection disabled for development environment to allow easy cleanup
  enable_deletion_protection = false
  
  drop_invalid_header_fields = true

  # Enable access logging for monitoring and troubleshooting
  access_logs {
    bucket  = var.logs_s3_bucket_name
    prefix  = "alb-logs"
    enabled = true
  }

  tags = {
    Name         = "${var.PrefixCode}-alb-ecs"
    resourcetype = "network"
    codeblock    = "load-balancer"
  }
}

# Listener for HTTP traffic
resource "aws_lb_listener" "frontend" {
  # checkov:skip=CKV_AWS_103:TLS check not applicable - ALB uses HTTP for workshop environment. Consider end-to-end HTTPS if certificate management overhead is acceptable.
  # checkov:skip=CKV_AWS_2:ALB uses HTTP for workshop environment to avoid certificate management complexity
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  # nosemgrep: insecure-load-balancer-tls-version - HTTP listener for workshop environment, TLS not applicable
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  tags = {
    Name         = "${var.PrefixCode}-alb-listener"
    resourcetype = "network"
    codeblock    = "load-balancer"
  }
}

# Output for accessing the application
output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_lb.main.dns_name}/wildlife"
}

# Security Group Rule to allow public HTTP access to ALB from workshop attendee
# nosemgrep: aws-ec2-security-group-allows-public-ingress - Public HTTP access required for workshop ALB
resource "aws_security_group_rule" "alb_http_public" {
  # checkov:skip=CKV_AWS_260:Public HTTP access required for workshop ALB. In production, consider using CloudFront or SSL
  type              = "ingress"
  from_port         = 80 
  to_port           = 80
  protocol          = "tcp"
  # nosemgrep: aws-ec2-security-group-allows-public-ingress - Public HTTP access required for workshop ALB
  cidr_blocks       = ["1.2.3.4/5"]
  security_group_id = data.aws_security_group.alb.id
  description       = "Allow HTTP access from user"
}