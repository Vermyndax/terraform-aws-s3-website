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

# S3 bucket for www redirect

resource "aws_s3_bucket" "site_www_redirect" {
  count = "${var.create_www_redirect_bucket == "true" ? 1 : 0}"
  bucket = "www.${var.site_tld}"
  region = "${var.site_region}"
  acl    = "public"
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
    redirect_all_requests_to = "http://${var.site_tld}"
  }
  tags = {
    Website-redirect = "${var.site_tld}"
  }
}



# S3 bucket for website artifacts (?)

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
  repository_name = "${var.codecommit_repo_name != "" ? var.site_tld : var.codecommit_repo_name}"
  description     = "This is the default repo for ${var.site_tld}"
}

# IAM roles for CodeCommit/CodeDeploy

# CodeDeploy supporting projects

# CodePipeline for deployment from Github to public site

# CloudFront distribution

# DNS entry pointing to public site - optional