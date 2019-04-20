resource "aws_codebuild_project" "frontend" {
  name         = "${var.project-name}-frontend-build"
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

    environment_variable {
      name  = "REACT_APP_QUIZ_API_URL"
      value = "${data.terraform_remote_state.infra.lb_endpoints[0]}"
    }
  }
}

resource "aws_codepipeline" "frontend" {
  name     = "${var.project-name}-frontend-pipeline"
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
      output_artifacts = ["source"]

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
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source"]
      output_artifacts = ["build"]
      version          = "1"

      configuration {
        ProjectName = "${aws_codebuild_project.frontend.id}"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["build"]
      version         = "1"

      configuration {
        BucketName = "flashcardify-frontend-dev"
        Extract    = "true"
      }
    }
  }
}
