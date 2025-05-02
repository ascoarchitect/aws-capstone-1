#!/bin/bash
set -e

function print_help {
    echo "AWS Infrastructure Capstone Project Deployment Script"
    echo ""
    echo "Usage: $0 [OPTION] [TYPE]"
    echo ""
    echo "Options:"
    echo "  --build-packer [TYPE]    Build the Packer AMI (TYPE: space or retro)"
    echo "  --test-vm [TYPE]         Create a test VM with Terraform (TYPE: space or retro)"
    echo "  --deploy-website [TYPE]  Deploy the complete website infrastructure (TYPE: space or retro)"
    echo "  --destroy [TYPE]         Destroy resources for specified type (or all if no type specified)"
    echo "  --help                   Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --build-packer space"
    echo "  $0 --deploy-website retro"
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
DEPLOYMENT_TYPE=""

# Parse the main command
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

# Parse the deployment type if provided
if [[ $# -gt 0 ]]; then
    if [[ "$1" == "space" || "$1" == "retro" ]]; then
        DEPLOYMENT_TYPE=$1
        shift
    else
        echo "Error: Deployment type must be 'space' or 'retro'"
        print_help
        exit 1
    fi
fi

# Validate we have a deployment type for actions that require it
if [[ ($BUILD_PACKER == true || $TEST_VM == true || $DEPLOY_WEBSITE == true) && -z "$DEPLOYMENT_TYPE" ]]; then
    echo "Error: You must specify a deployment type (space or retro) with this command"
    print_help
    exit 1
fi

# Set variables based on deployment type
if [[ "$DEPLOYMENT_TYPE" == "space" ]]; then
    PROJECT_NAME="space-invaders"
    AMI_NAME_PREFIX="space-invaders-ami"
    AMI_NAME_PATTERN="space-invaders-ami-*"
    GIT_REPO="https://github.com/drehnstrom/space-invaders"
elif [[ "$DEPLOYMENT_TYPE" == "retro" ]]; then
    PROJECT_NAME="retro-emulator"
    AMI_NAME_PREFIX="retro-emulator-ami"
    AMI_NAME_PATTERN="retro-emulator-ami-*"
    GIT_REPO="https://github.com/lrusso/Emulatrix"
fi

# Working directory
PROJECT_ROOT=$(pwd)

# Build Packer AMI
if [ "$BUILD_PACKER" = true ]; then
    echo "Building $PROJECT_NAME AMI..."
    cd "$PROJECT_ROOT/packer"
    
    # Create a temporary variables file
    cat > variables.auto.pkrvars.hcl <<EOF
project_name   = "$PROJECT_NAME"
git_repo       = "$GIT_REPO"
ami_name_prefix = "$AMI_NAME_PREFIX"
EOF
    
    packer init .
    packer build -var-file=variables.auto.pkrvars.hcl game-ami.pkr.hcl
    
    # Clean up the temporary file
    rm variables.auto.pkrvars.hcl
    
    echo "$PROJECT_NAME AMI built successfully."
fi

# Deploy test VM
if [ "$TEST_VM" = true ]; then
    echo "Deploying $PROJECT_NAME test VM..."
    cd "$PROJECT_ROOT/terraform/test-vm"
    
    # Create a temporary tfvars file for the test VM
    cat > test-vm.auto.tfvars <<EOF
project_name = "$PROJECT_NAME"
ami_name_pattern = "$AMI_NAME_PATTERN"
EOF
    
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
            echo "Health check passed! Web server is running and serving content."
            
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
    echo "Deploying $PROJECT_NAME website infrastructure..."
    cd "$PROJECT_ROOT/terraform"
    
    # Create a temporary tfvars file
    cat > terraform.auto.tfvars <<EOF
project_name = "$PROJECT_NAME"
ami_name_pattern = "$AMI_NAME_PATTERN"
EOF
    
    terraform init
    terraform plan -out=website.tfplan
    terraform apply website.tfplan
    
    # Display outputs
    echo "Website infrastructure deployed successfully!"
    echo "Website URL: $(terraform output -raw website_url)"
fi

# Destroy infrastructure
if [ "$DESTROY" = true ]; then
    if [[ -z "$DEPLOYMENT_TYPE" ]]; then
        echo "Destroying all infrastructure..."
        
        # Check and destroy any test VMs
        if [ -d "$PROJECT_ROOT/terraform/test-vm/.terraform" ]; then
            cd "$PROJECT_ROOT/terraform/test-vm"
            terraform destroy -auto-approve
        fi
        
        # Check and destroy any website infrastructure
        if [ -d "$PROJECT_ROOT/terraform/.terraform" ]; then
            cd "$PROJECT_ROOT/terraform"
            terraform destroy -auto-approve
        fi
        
        # Clean up all AMIs
        echo "Cleaning up all AMIs and snapshots..."
        AMI_IDS=$(aws ec2 describe-images --owners self --filters "Name=name,Values=space-invaders-ami-*,retro-emulator-ami-*" --query "Images[*].ImageId" --output text)
        
        echo "Cleaning up temporary files..."
        rm -f "$PROJECT_ROOT/terraform/test-vm/"*.auto.tfvars
        rm -f "$PROJECT_ROOT/terraform/"*.auto.tfvars
        rm -f "$PROJECT_ROOT/packer/"*.auto.pkrvars.hcl    
    else
        echo "Destroying $PROJECT_NAME infrastructure..."
        
        # Create temporary tfvars files for the specific deployment
        echo "project_name = \"$PROJECT_NAME\"" > "$PROJECT_ROOT/terraform/test-vm/test-vm.auto.tfvars"
        echo "project_name = \"$PROJECT_NAME\"" > "$PROJECT_ROOT/terraform/terraform.auto.tfvars"
        
        # Check and destroy test VM for the specific deployment
        if [ -d "$PROJECT_ROOT/terraform/test-vm/.terraform" ]; then
            cd "$PROJECT_ROOT/terraform/test-vm"
            terraform destroy -auto-approve
        fi
        
        # Check and destroy website infrastructure for the specific deployment
        if [ -d "$PROJECT_ROOT/terraform/.terraform" ]; then
            cd "$PROJECT_ROOT/terraform"
            terraform destroy -auto-approve
        fi
        
        # Clean up AMIs for the specific deployment
        echo "Cleaning up $PROJECT_NAME AMIs and snapshots..."
        AMI_IDS=$(aws ec2 describe-images --owners self --filters "Name=name,Values=$AMI_NAME_PATTERN" --query "Images[*].ImageId" --output text)

        # Clean up temporary tfvars files for this deployment
        echo "Cleaning up temporary files..."
        rm -f "$PROJECT_ROOT/terraform/test-vm/test-vm.auto.tfvars"
        rm -f "$PROJECT_ROOT/terraform/terraform.auto.tfvars"
        rm -f "$PROJECT_ROOT/packer/"*.auto.pkrvars.hcl
    fi
    
    # Process AMIs and snapshots
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
        echo "No AMIs found to clean up."
    fi
    
    echo "Infrastructure destroyed successfully!"
fi

echo "Script completed successfully!"