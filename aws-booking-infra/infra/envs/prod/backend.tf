terraform {
  backend "s3" {
    bucket = "replace-with-prod-terraform-state-bucket"
    key    = "booking-infra/prod/terraform.tfstate"
    region = "ap-south-1"
  }
}
