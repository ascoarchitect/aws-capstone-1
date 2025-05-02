#!/bin/bash
set -e

echo "Setting up the environment for AWS Infrastructure Capstone Project on Amazon Linux 2..."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Installing AWS CLI version 2..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
    echo "AWS CLI installed successfully."
else
    echo "AWS CLI is already installed."
fi

# Configure AWS CLI
echo "Configuring AWS CLI..."
aws configure

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "Installing Terraform..."
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
    sudo yum -y install terraform
    echo "Terraform installed successfully."
else
    echo "Terraform is already installed."
fi

# Check if Packer is installed
if ! command -v packer &> /dev/null; then
    echo "Installing Packer..."
    sudo yum -y install yum-utils
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
    sudo yum -y install packer
    echo "Packer installed successfully."
else
    echo "Packer is already installed."
fi

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "Installing Git..."
    sudo yum install -y git
    echo "Git installed successfully."
else
    echo "Git is already installed."
fi

# Install additional dependencies that might be needed
echo "Installing additional dependencies..."
sudo yum install -y wget unzip jq

# Verify installations
echo "Verifying installed tools..."
aws --version
terraform --version
packer --version
git --version

echo "Environment setup completed successfully!"