#!/bin/bash
set -e

# Git repo URL is passed as an environment variable
# GIT_REPO_URL

# Update system packages
sudo yum update -y

# Install Apache web server and Git
sudo yum install -y httpd git

# Start and enable Apache
sudo systemctl start httpd
sudo systemctl enable httpd

# Create a temporary directory for Git operations
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Clone the repository using the passed URL
echo "Cloning repository: $GIT_REPO_URL"
git clone "$GIT_REPO_URL" .

# Copy the application to the web server root
sudo rm -f /var/www/html/index.html
sudo cp -R * /var/www/html/

# Set proper permissions
sudo chown -R apache:apache /var/www/html/
sudo chmod -R 755 /var/www/html/

# Create health check endpoint for load balancer
echo "<html><body><h1>Health Check OK</h1></body></html>" | sudo tee /var/www/html/health.html

# Clean up the temporary directory
cd
rm -rf "$TEMP_DIR"

echo "Application installed successfully!"