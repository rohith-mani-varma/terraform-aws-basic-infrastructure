# terraform-aws-production-infra

Simple Terraform configuration that provisions:

- A VPC with a public subnet and internet gateway
- Security group allowing:
  - SSH (22) from your current IP
  - HTTP (80) and HTTPS (443) from anywhere
- An Ubuntu EC2 instance in the public subnet
- An auto-generated SSH key pair and local `portfolio.pem`
- Optional bootstrap script (`install.sh`) that is uploaded and executed on the instance

## Files

- `provider.tf` — Terraform block and provider configuration (AWS, HTTP, TLS, local)
- `variables.tf` — Input variables (region, instance_type, vpc_cidr, subnet_cidr)
- `main.tf` — Networking, security group, key pair, EC2 instance, and provisioners
- `outputs.tf` — Outputs (EC2 public IP and EC2 instance ID)
- `terraform.tfvars` — Example/default values for the variables
- `install.sh` — Your bootstrap script that runs on the VM after it’s created

## Usage

```bash
cd terraform-aws-production-infra   # or your project folder

# Initialize providers and backend
terraform init

# See what will be created
terraform plan

# Create the infrastructure
terraform apply
```

After apply, Terraform will output:

- `instance_public_ip` — the public IP of the Ubuntu EC2 instance
- `instance_id` — the EC2 instance ID

You can SSH into the instance with:

```bash
ssh -i portfolio.pem ubuntu@<instance_public_ip>
```

Replace `<instance_public_ip>` with the value from Terraform output.

