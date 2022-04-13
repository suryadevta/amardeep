provider "aws" {
  region     = "us-east-1"
  version    = ">= 3.63.0"
}


terraform {
  backend "s3" {
    bucket     = "gravystackterraform"
    key        = "prod/terraform.tfstate"
    region     = "us-east-1"
  }
}