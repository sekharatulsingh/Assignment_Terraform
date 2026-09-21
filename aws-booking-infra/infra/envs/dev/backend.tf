terraform {
  backend "s3" {
    bucket = "replace-with-dev-terraform-state-bucket"
    key    = "booking-infra/dev/terraform.tfstate"
    region = "ap-south-1"
  }
}
