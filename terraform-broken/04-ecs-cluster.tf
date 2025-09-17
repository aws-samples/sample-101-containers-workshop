# ECS Cluster with Fargate and EC2 Capacity Providers

# Data source for ECS optimized AMI
data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/arm64/recommended/image_id"
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.PrefixCode}-ecs"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name         = "${var.PrefixCode}-ecs"
    resourcetype = "compute"
    codeblock    = "ecs-cluster"
  }
}

# ECS Capacity Provider for EC2
resource "aws_ecs_capacity_provider" "ec2" {
  name = "${var.PrefixCode}-capacity-ec2"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 2
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }

  tags = {
    Name         = "${var.PrefixCode}-capacity-ec2"
    resourcetype = "compute"
    codeblock    = "ecs-cluster"
  }
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = [
    "FARGATE",
    "FARGATE_DOT",
    aws_ecs_capacity_provider.ec2.name
  ]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# Launch Template for EC2 instances
resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.PrefixCode}-ecs-launchtemplate-"
  image_id      = "ami-12345678"
  instance_type = "t4g.small"
  key_name      = data.aws_key_pair.main.key_name

  vpc_security_group_ids = [data.aws_security_group.app.id]

  iam_instance_profile {
    name = data.aws_iam_instance_profile.ecs.name
  }

  user_data = base64encode(file("${path.module}/../workshop/app-ec2.sh"))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name         = "${var.PrefixCode}-ecs-instance"
      resourcetype = "compute"
      codeblock    = "ecs-cluster"
    }
  }

  tags = {
    Name         = "${var.PrefixCode}-ecs-launch-template"
    resourcetype = "compute"
    codeblock    = "ecs-cluster"
  }
}

# Auto Scaling Group for EC2 instances
resource "aws_autoscaling_group" "ecs" {
  name                      = "${var.PrefixCode}-asg-ecs"
  vpc_zone_identifier       = data.aws_subnets.private.ids
  target_group_arns         = []
  health_check_type         = "EC2"
  health_check_grace_period = 300

  min_size         = 2
  max_size         = 2 # Updated for capacity scaling
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.PrefixCode}-asg-ecs"
    propagate_at_launch = false
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = false
  }

  tag {
    key                 = "resourcetype"
    value               = "compute"
    propagate_at_launch = false
  }

  tag {
    key                 = "codeblock"
    value               = "ecscluster"
    propagate_at_launch = false
  }
}