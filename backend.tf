terraform {
  backend "s3" {
    bucket       = "rohith-tf-state"
    key          = "aws-infra/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}