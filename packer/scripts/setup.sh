#!/bin/bash
set -e

# Update system packages
sudo yum update -y

# Install Apache web server and Git
sudo yum install -y httpd git

# Start and enable Apache
sudo systemctl start httpd
sudo systemctl enable httpd

# Create a temporary directory and clone the repo there
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
git clone https://github.com/drehnstrom/space-invaders .

# Copy the files to the web server root (without .git directory)
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

echo "Space Invaders application installed successfully!"