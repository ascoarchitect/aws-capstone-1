# AWS Infrastructure Capstone Project

This project demonstrates the deployment of AWS infrastructure using Terraform and Packer. It includes setting up a Terraform environment, creating a test VM, and deploying a complete Space Invaders website with auto-scaling capabilities.

## Project Structure

```
aws-capstone-1/
├── README.md
├── .gitignore
├── emulator-roms/
│   ├── Legend of Zelda.nes
│   ├── Super Mario Bros.nes
│   ├── Top Gun.nes
├── scripts/
│   ├── setup-environment.sh      # Set up the environment
│   └── deploy.sh                 # Deploy the infrastructure
├── packer/
│   ├── game-ami.pkr.pkr.hcl      # Packer template
│   └── scripts/
│       └── setup.sh              # Installation script for the AMI
└── terraform/
    ├── main.tf                   # Main Terraform configuration
    ├── data.tf                   # AMI dynamic lookup
    ├── variables.tf              # Input variables
    ├── outputs.tf                # Output values
    ├── provider.tf               # Provider configuration
    ├── versions.tf               # Version constraints
    ├── test-vm/                  # Test VM configuration
    │   ├── main.tf               # VM resources
    │   ├── variables.tf          # VM variables
    │   ├── outputs.tf            # VM outputs
    │   └── data.tf               # AMI lookup
    └── modules/                  # Reusable modules
        ├── vpc/                  # VPC module
        ├── security/             # Security groups module
        ├── compute/              # Auto Scaling Group module
        └── alb/                  # Application Load Balancer module
```

## Setting Up a Deployment EC2 Instance

Follow these steps to deploy an Amazon Linux 2 EC2 instance to run the project:

### Launch an Amazon Linux 2 Instance

1. Sign in to the AWS Management Console
2. Navigate to EC2 Dashboard
3. Click "Launch Instance"
4. Give the instance the name 'Deployment-VM' and Choose "Amazon Linux 2 AMI"
5. Select instance type (t2.micro is eligible for free tier)
6. Configure instance details:
    - Network: Default VPC
    - Auto-assign Public IP: Enable
7. Add storage (8 GB is sufficient)
8. Add tags as required
9. Allow wizard to create security group as recommended
10. Proceed without key pair then launch instance
11. Wait for the instance to initialise

### Connect to Your Instance

1. Navigate to the EC2 service and select Instances
2. Find your 'Deployment-VM' instance
3. Select 'Connect'
4. Use EC2 Instance Connect and select 'Connect'

### Clone the Repository

```bash
# Install Git if not already installed
sudo yum install -y git

# Clone the repository
git clone https://github.com/ascoarchitect/aws-capstone-1.git
cd aws-capstone-1

# Make scripts executable
chmod +x scripts/setup-environment.sh scripts/deploy.sh
```

### Setup the Environment

Pre-req! You will need to have AWS CLI credentials already created to run this project. The IAM user will need to have the following permissions to deploy the project:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "iam:PassRole",
                "iam:CreateServiceLinkedRole",
                "cloudwatch:PutMetricAlarm",
                "cloudwatch:DeleteAlarms",
                "cloudwatch:DescribeAlarms"
            ],
            "Resource": "*"
        }
    ]
}
```

Next, you will need to run the environment setup script.

```bash
# Install required tools
./scripts/setup-environment.sh
```

The script will install the required dependencies and configure the AWS CLI. You will need to provide your AWS Access Key ID and Secret Key ID as part of this step.

Select ```eu-west-1``` as the region and ```json``` as the output format.

### tfvars Configuration

There is a demo ```terraform.tfvars``` file within the project which is to be used for test purposes. For best-practice security, this file should always be excluded from production repositories as they often contain sensitive information.

## Multiple Game Deployments

This project supports deployment of multiple game applications:

1. **Space Invaders**: A classic arcade game
2. **Retro Emulator**: A web-based retro game emulator

You can specify which game to deploy by adding either `space` or `retro` to the deployment commands.

An example Nintendo Entertainment System (NES) ROM for Legend of Zelda is available in the emulator-rom repo folder. When the website is deployed, you upload this ROM onto the website to load the game into the browser.

Note: If you start your project build steps with one game type, you need to ensure that you use that game type for the whole project. Shoudl you wish to use the other game type then you need to destroy the resources first.

## Running the Project

### Build Game AMI

```bash
# Build Space Invaders AMI
./scripts/deploy.sh --build-packer space

# or

# Build Retro Emulator AMI
./scripts/deploy.sh --build-packer retro
```

### Deploy Test VM

Note: You will need to have created the AMI first before deploying the Test VM.

```bash
# Test Space Invaders VM
./scripts/deploy.sh --test-vm space

# or

# Test Retro Emulator VM
./scripts/deploy.sh --test-vm retro
```

This will:

- Create a simple EC2 instance in the default VPC
- Use the AMI created by Packer
- Set up security groups for HTTP access
- Verify the instance is running
- Test that the web server is properly serving content

### Deploy Website Infrastructure

```bash
# This deploys the complete website with VPC, ALB, and ASG
./scripts/deploy.sh --deploy-website space

# or

./scripts/deploy.sh --deploy-website retro
```

This creates:

- A new VPC with public and private subnets
- NAT Gateway for outbound connectivity
- Application Load Balancer in public subnets
- Auto Scaling Group in private subnets
- Security groups for proper access control

### Clean Up Resources

```bash
# This destroys all created resources
./scripts/deploy.sh --destroy
```

This will:

- Destroy all Terraform-managed resources
- Deregister the AMI
- Delete associated snapshots

## Project Components

- VPC: Network infrastructure with public and private subnets
- Security Groups: Properly configured security for ALB and EC2 instances
- Auto Scaling Group: Scalable compute capacity
- Application Load Balancer: Distributes traffic across instances
- Website: Space Invaders web application

## Troubleshooting

- Permission Issues: Ensure your IAM user or role has the necessary permissions
- AMI Not Found: Check that the Packer build completed successfully
- Terraform State: If Terraform state becomes corrupted, you might need to run ```terraform init``` again
- HTTP Not Working: Check security group rules and health check configuration

Remember to run ```terraform destroy``` or ```./scripts/deploy.sh --destroy``` when you've completed the project to avoid incurring unnecessary AWS charges.