terraform {
  backend "s3" {
    bucket  = "flashcardify-ci-cd"
    key     = "state/terraform.tfstate"
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

resource "aws_codebuild_project" "default" {
  name         = "${var.project-name}-build"
  service_role = "${aws_iam_role.build_role.arn}"

  source = {
    type = "CODEPIPELINE"
  }

  artifacts = {
    type = "CODEPIPELINE"
  }

  environment = {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/nodejs:10.14.1"
    type         = "LINUX_CONTAINER"
  }
}

resource "aws_codepipeline" "default" {
  name     = "${var.project-name}-pipeline"
  role_arn = "${aws_iam_role.pipeline_role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.artifact_store.bucket}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["test"]

      configuration {
        OAuthToken = "${var.github-oauth-token}"
        Owner      = "leevilehtonen"
        Repo       = "flashcardify-frontend"
        Branch     = "master"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["test"]
      version         = "1"

      configuration {
        ProjectName = "${aws_codebuild_project.default.id}"
      }
    }
  }
}
