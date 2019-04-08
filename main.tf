terraform {
  backend "s3" {
    bucket  = "flashcardify-ci-cd"
    key     = "state/terraform.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}

data "terraform_remote_state" "infra" {
  backend   = "s3"
  workspace = "dev"

  config {
    bucket  = "flashcardify-infra"
    key     = "terraform.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}

provider "aws" {
  region = "${var.region}"
}

resource "aws_s3_bucket" "artifact_store" {
  bucket        = "flashcardify-artifact"
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
