provider "aws" {
  region = var.region
}

# Create a simple EC2 instance for testing
resource "aws_instance" "test" {
  ami           = data.aws_ami.space_invaders.id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.test.id]

  tags = {
    Name        = "${var.project_name}-test-vm"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Create a security group for the test instance
resource "aws_security_group" "test" {
  name        = "${var.project_name}-test-sg"
  description = "Security group for test instance"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-test-sg"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}