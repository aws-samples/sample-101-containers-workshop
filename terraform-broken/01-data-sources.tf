# Data sources for existing infrastructure created by the Workshop

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["wildlife-vpc01"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  filter {
    name   = "tag:Name"
    values = ["wildlife-subnet-public*"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  filter {
    name   = "tag:Name"
    values = ["wildlife-subnet-private*"]
  }
}

data "aws_security_group" "app" {
  filter {
    name   = "group-name"
    values = ["wildlife-securitygroup-app"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

data "aws_security_group" "alb" {
  filter {
    name   = "group-name"
    values = ["wildlife-securitygroup-alb"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

data "aws_iam_role" "ecs_task_execution" {
  name = "wildlife-iamrole-ecs-task-execution"
}

data "aws_iam_role" "ecs_task" {
  name = "wildlife-iamrole-ecs-task"
}

data "aws_iam_instance_profile" "ecs" {
  name = "wildlife-iamprofile-ecs"
}

data "aws_key_pair" "main" {
  key_name = "wildlife-ec2-keypair"
}

data "aws_iam_policy" "application_data_policy" {
  name = "wildlife-iampolicy-application-data"
}

data "aws_kms_key" "cmk" {
  key_id = "alias/wildlife-kms-cmk"
}