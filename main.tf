terraform {
  required_version = ">= 0.11.11" # 11-11 make a wish
}

# S3 bucket for website, public hosting

resource "aws_s3_bucket" "main_site" {
    bucket = "${var.site_tld}"
    region = "${var.site_region}"
    acl = "public-read"
    policy = <<EOF
{
  "Id": "bucket_policy_site",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "s3_bucket_policy_website",
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.site_tld}/*",
      "Principal": "*"
    }
  ]
}
EOF
    website {
        index_document = "index.html"
        error_document = "404.html"
    }
    # tags {
    # }
    # force_destroy = true
}

# S3 bucket for www redirect (optional)

resource "aws_s3_bucket" "site_www_redirect" {
  count = "${var.create_www_redirect_bucket == "true" ? 0 : 1}"
  bucket = "www.${var.site_tld}"
  region = "${var.site_region}"
  acl    = "private"

  website {
    redirect_all_requests_to = "${var.site_tld}"
  }

  tags = {
    Website-redirect = "${var.site_tld}"
  }
}



# S3 bucket for website artifacts

resource "aws_s3_bucket" "site_artifacts" {
  bucket = "${var.site_tld}-codedeploy-artifacts"
  region = "${var.site_region}"
  acl    = "private"

  tags = {
    Website-artifacts = "${var.site_tld}"
  }
}

# CodeCommit repo (optional)

resource "aws_codecommit_repository" "codecommit_site_repo" {
  count = "${var.create_codecommit_repo == "true" ? 1 : 0}"
  repository_name = "${var.codecommit_repo_name != "" ? var.codecommit_repo_name : var.site_tld}"
  description     = "This is the default repo for ${var.site_tld}"
}

# IAM roles for CodeCommit/CodeDeploy

resource "aws_iam_role" "codepipeline_iam_role" {
  name = "${var.site_tld}-codepipeline-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.site_tld}-codepipeline-policy"
  role = "${aws_iam_role.codepipeline_iam_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning"
      ],
      "Resource": [
        "${aws_s3_bucket.site_artifacts.arn}",
        "${aws_s3_bucket.site_artifacts.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# CodeDeploy supporting projects

# CodePipeline for deployment from Github to public site

# CloudFront distribution

# DNS entry pointing to public site - optional

# TODO: SNS to support notifications for commit and build events

# TODO: Conditionally create KMS key for encryption on pipeline