# EFS Storage for Application

# EFS File System for MongoDB persistent storage
resource "aws_efs_file_system" "mongodb" {
  creation_token = "${var.PrefixCode}-mongodb"

  performance_mode                = "standardPurpose"
  throughput_mode                 = "provisioned"
  provisioned_throughput_in_mibps = 100
  encrypted                       = true
  kms_key_id                      = data.aws_kms_key.cmk.arn

  tags = {
    Name         = "${var.PrefixCode}-mongodb-efs"
    resourcetype = "storage"
    codeblock    = "efs"
  }
}

# EFS Mount Targets in private subnets
resource "aws_ebs_mount_target" "mongodb" {
  count = length(data.aws_subnets.private.ids)

  file_system_id  = aws_ebs_file_system.mongodb
  subnet_id       = data.aws_subnets.private.ids[count.index]
  security_groups = [data.aws_security_group.app.id]
}