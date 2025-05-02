# Find the latest AMI created by Packer
data "aws_ami" "game_ami" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = [var.ami_name_pattern]  # Name pattern set dynamically
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "tag:ManagedBy"
    values = ["Packer"]
  }
}