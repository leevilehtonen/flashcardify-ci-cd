resource "aws_codebuild_project" "service" {
  count        = "${length(var.services)}"
  name         = "${var.project-name}-${var.services[count.index]}-service-build"
  service_role = "${aws_iam_role.build_role.arn}"

  source = {
    type = "CODEPIPELINE"
  }

  artifacts = {
    type = "CODEPIPELINE"
  }

  environment = {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/docker:18.09.0-1.7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "IMAGE_NAME"
      value = "${data.terraform_remote_state.infra.ecs_container_names[count.index]}"
    }

    environment_variable {
      name  = "IMAGE_REPO_URL"
      value = "${data.terraform_remote_state.infra.ecr_repositories[count.index]}"
    }
  }
}

resource "aws_codepipeline" "service" {
  count    = "${length(var.services)}"
  name     = "${var.project-name}-${var.services[count.index]}-service-pipeline"
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
        Repo       = "flashcardify-${var.services[count.index]}-service"
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
        ProjectName = "${aws_codebuild_project.service.*.id[count.index]}"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build"]
      version         = "1"

      configuration {
        ClusterName = "${data.terraform_remote_state.infra.ecs_cluster_name}"
        ServiceName = "${data.terraform_remote_state.infra.ecs_service_names[count.index]}"
        FileName    = "imagedefinitions.json"
      }
    }
  }
}
