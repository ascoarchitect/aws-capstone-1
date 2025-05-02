#!/bin/bash
set -e

function print_help {
    echo "AWS Infrastructure Capstone Project Deployment Script"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  --build-packer       Build the Packer AMI"
    echo "  --test-vm            Create a test VM with Terraform in default VPC"
    echo "  --deploy-website     Deploy the complete website infrastructure"
    echo "  --destroy            Destroy all resources"
    echo "  --help               Display this help message"
    echo ""
    echo "Example: $0 --build-packer --deploy-website"
}

# Parse arguments
if [[ $# -eq 0 ]]; then
    print_help
    exit 0
fi

BUILD_PACKER=false
TEST_VM=false
DEPLOY_WEBSITE=false
DESTROY=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --build-packer)
            BUILD_PACKER=true
            shift
            ;;
        --test-vm)
            TEST_VM=true
            shift
            ;;
        --deploy-website)
            DEPLOY_WEBSITE=true
            shift
            ;;
        --destroy)
            DESTROY=true
            shift
            ;;
        --help)
            print_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_help
            exit 1
            ;;
    esac
done

# Working directory
PROJECT_ROOT=$(pwd)

# Build Packer AMI
if [ "$BUILD_PACKER" = true ]; then
    echo "Building Packer AMI..."
    cd "$PROJECT_ROOT/packer"
    packer init .
    packer build space-invaders.pkr.hcl
    echo "Packer AMI built successfully."
fi

# Deploy test VM
if [ "$TEST_VM" = true ]; then
    echo "Deploying test VM..."
    cd "$PROJECT_ROOT/terraform/test-vm"
    terraform init
    terraform plan -out=test-vm.tfplan
    terraform apply test-vm.tfplan
    
    # Display outputs
    echo "Test VM deployed successfully!"
    PUBLIC_IP=$(terraform output -raw public_ip)
    PUBLIC_DNS=$(terraform output -raw public_dns)
    
    echo "Public IP: $PUBLIC_IP"
    echo "Public DNS: $PUBLIC_DNS"
    
    # Wait for the web server to become available
    echo "Waiting for web server to initialize (this may take a minute)..."
    sleep 30
    
    # Check if the health page is accessible
    echo "Performing health check..."
    MAX_ATTEMPTS=10
    ATTEMPT=1
    HEALTH_CHECK_PASSED=false
    
    while [ $ATTEMPT -le $MAX_ATTEMPTS ] && [ "$HEALTH_CHECK_PASSED" = false ]; do
        echo "Attempt $ATTEMPT of $MAX_ATTEMPTS..."
        if curl -s --head --fail "http://$PUBLIC_IP/health.html" > /dev/null; then
            HEALTH_CHECK_PASSED=true
            echo "Health check passed! Apache is running and serving content."
            
            # Get the actual content for more thorough verification
            HEALTH_CONTENT=$(curl -s "http://$PUBLIC_IP/health.html")
            echo "Health page content:"
            echo "$HEALTH_CONTENT"
        else
            echo "Health check failed. Waiting 10 seconds before retrying..."
            sleep 10
            ATTEMPT=$((ATTEMPT + 1))
        fi
    done
    
    if [ "$HEALTH_CHECK_PASSED" = false ]; then
        echo "WARNING: Could not access health.html after $MAX_ATTEMPTS attempts."
        echo "You may need to check the instance configuration and security groups."
    fi
fi

# Deploy website infrastructure
if [ "$DEPLOY_WEBSITE" = true ]; then
    echo "Deploying Space Invaders website infrastructure..."
    cd "$PROJECT_ROOT/terraform"
    terraform init
    terraform plan -out=website.tfplan
    terraform apply website.tfplan --auto-approve
    
    # Display outputs
    echo "Website infrastructure deployed successfully!"
    echo "Website URL: $(terraform output -raw website_url)"
fi

# Destroy infrastructure
if [ "$DESTROY" = true ]; then
    echo "Destroying infrastructure..."
    
    # First check if test VM exists and destroy it
    if [ -d "$PROJECT_ROOT/terraform/test-vm/.terraform" ]; then
        cd "$PROJECT_ROOT/terraform/test-vm"
        terraform destroy -auto-approve
    fi
    
    # Then check if website infrastructure exists and destroy it
    if [ -d "$PROJECT_ROOT/terraform/.terraform" ]; then
        cd "$PROJECT_ROOT/terraform"
        terraform destroy -auto-approve
    fi
    
    # Delete AMIs and snapshots created by Packer
    echo "Cleaning up AMIs and snapshots..."
    
    # Find AMIs with the Space Invaders name pattern
    AMI_IDS=$(aws ec2 describe-images --owners self --filters "Name=name,Values=space-invaders-ami-*" --query "Images[*].ImageId" --output text)
    
    if [ -n "$AMI_IDS" ]; then
        echo "Found AMIs to delete: $AMI_IDS"
        
        # Process each AMI
        for AMI_ID in $AMI_IDS; do
            echo "Processing AMI: $AMI_ID"
            
            # Get snapshot IDs associated with this AMI
            SNAPSHOT_IDS=$(aws ec2 describe-images --image-ids "$AMI_ID" --query "Images[*].BlockDeviceMappings[*].Ebs.SnapshotId" --output text)
            
            # Deregister the AMI
            echo "Deregistering AMI: $AMI_ID"
            aws ec2 deregister-image --image-id "$AMI_ID"
            
            # Delete associated snapshots
            if [ -n "$SNAPSHOT_IDS" ]; then
                echo "Deleting associated snapshots: $SNAPSHOT_IDS"
                for SNAPSHOT_ID in $SNAPSHOT_IDS; do
                    echo "Deleting snapshot: $SNAPSHOT_ID"
                    aws ec2 delete-snapshot --snapshot-id "$SNAPSHOT_ID"
                done
            else
                echo "No snapshots found for AMI: $AMI_ID"
            fi
        done
        
        echo "AMI and snapshot cleanup completed."
    else
        echo "No Space Invaders AMIs found to clean up."
    fi
    
    echo "Infrastructure destroyed successfully!"
fi

echo "Script completed successfully!"