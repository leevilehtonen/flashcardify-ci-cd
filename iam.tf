data "aws_iam_policy_document" "pipeline_assume" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    effect = "Allow"
  }
}

data "aws_iam_policy_document" "build_assume" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    effect = "Allow"
  }
}

data "aws_iam_policy_document" "pipeline_default" {
  statement {
    actions = [
      "s3:*",
      "iam:PassRole",
    ]

    resources = ["*"]
    effect    = "Allow"
  }
}

data "aws_iam_policy_document" "build_default" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
    effect    = "Allow"
  }
}

data "aws_iam_policy_document" "pipeline_s3" {
  statement {
    actions = [
      "s3:*",
    ]

    resources = [
      "${aws_s3_bucket.artifact_store.arn}",
      "${aws_s3_bucket.artifact_store.arn}/*",
    ]

    effect = "Allow"
  }
}

data "aws_iam_policy_document" "pipeline_ecs" {
  statement {
    actions = [
      "ecs:*",
    ]

    resources = [
      "*",
    ]

    effect = "Allow"
  }
}

data "aws_iam_policy_document" "build_ecr" {
  statement {
    actions = [
      "ecr:CreateRepository",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]

    resources = [
      "*",
    ]

    effect = "Allow"
  }
}

data "aws_iam_policy_document" "pipeline_codebuild" {
  statement {
    actions = [
      "codebuild:*",
    ]

    resources = ["*"]

    effect = "Allow"
  }
}

resource "aws_iam_role" "pipeline_role" {
  name               = "${var.project-name}-pipeline-role"
  assume_role_policy = "${data.aws_iam_policy_document.pipeline_assume.json}"
}

resource "aws_iam_role" "build_role" {
  name               = "${var.project-name}-build-role"
  assume_role_policy = "${data.aws_iam_policy_document.build_assume.json}"
}

resource "aws_iam_policy" "pipeline_default" {
  name   = "${var.project-name}-pipeline-policy"
  policy = "${data.aws_iam_policy_document.pipeline_default.json}"
}

resource "aws_iam_policy" "build_default" {
  name   = "${var.project-name}-build-policy"
  policy = "${data.aws_iam_policy_document.build_default.json}"
}

resource "aws_iam_policy" "build_ecr" {
  name   = "${var.project-name}-build-ecr-policy"
  policy = "${data.aws_iam_policy_document.build_ecr.json}"
}

resource "aws_iam_policy" "pipeline_s3" {
  name   = "${var.project-name}-pipeline-s3-policy"
  policy = "${data.aws_iam_policy_document.pipeline_s3.json}"
}

resource "aws_iam_policy" "pipeline_ecs" {
  name   = "${var.project-name}-pipeline-ecs-policy"
  policy = "${data.aws_iam_policy_document.pipeline_ecs.json}"
}

resource "aws_iam_policy" "pipeline_codebuild" {
  name   = "${var.project-name}-pipeline-codebuild-policy"
  policy = "${data.aws_iam_policy_document.pipeline_codebuild.json}"
}

resource "aws_iam_role_policy_attachment" "pipeline_default" {
  role       = "${aws_iam_role.pipeline_role.id}"
  policy_arn = "${aws_iam_policy.pipeline_default.arn}"
}

resource "aws_iam_role_policy_attachment" "build_default" {
  role       = "${aws_iam_role.build_role.id}"
  policy_arn = "${aws_iam_policy.build_default.arn}"
}

resource "aws_iam_role_policy_attachment" "build_s3" {
  role       = "${aws_iam_role.build_role.id}"
  policy_arn = "${aws_iam_policy.pipeline_s3.arn}"
}

resource "aws_iam_role_policy_attachment" "pipeline_s3" {
  role       = "${aws_iam_role.pipeline_role.id}"
  policy_arn = "${aws_iam_policy.pipeline_s3.arn}"
}

resource "aws_iam_role_policy_attachment" "pipeline_ecs" {
  role       = "${aws_iam_role.pipeline_role.id}"
  policy_arn = "${aws_iam_policy.pipeline_ecs.arn}"
}

resource "aws_iam_role_policy_attachment" "pipeline_codebuild" {
  role       = "${aws_iam_role.pipeline_role.id}"
  policy_arn = "${aws_iam_policy.pipeline_codebuild.arn}"
}

resource "aws_iam_role_policy_attachment" "build_ecr" {
  role       = "${aws_iam_role.build_role.id}"
  policy_arn = "${aws_iam_policy.build_ecr.arn}"
}
