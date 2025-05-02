# Find the latest Space Invaders AMI created by Packer
data "aws_ami" "space_invaders" {
  most_recent = true
  owners      = ["self"]  # AMIs owned by your account

  filter {
    name   = "name"
    values = ["space-invaders-ami-*"]  # Name pattern used in the Packer template
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