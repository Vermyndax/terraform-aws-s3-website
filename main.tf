terraform {
  required_version = ">= 0.11.11" # 11-11 make a wish
}

# TODO: Conditionally create KMS key for encryption on pipeline

# S3 bucket for website, public hosting
resource "aws_s3_bucket" "main_site" {
    bucket = "${var.site_tld}"
    region = "${var.site_region}"
    acl = "private"
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
      "Principal": {"CanonicalUser":"${aws_cloudfront_origin_access_identity.origin_access_identity.s3_canonical_user_id}"}
    }
  ]
}
EOF
    website {
        index_document = "${var.root_page_object}"
        error_document = "${var.error_page_object}"
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

# TODO: Add bucket for S3 logging
# Should give a parameter to create
# CloudFront should accept a parameter for S3 logging bucket and if it doesn't exist, then create one

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

# CodePipeline for deployment from Github to public site

# TODO: Add more parameterization
# TODO: Add logging to S3 bucket

# CloudFront distribution
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Origin access identity for ${var.site_tld}"
}

resource "aws_cloudfront_distribution" "site_cloudfront_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.main_site.website_endpoint}"
    origin_id = "${var.site_tld}"
    s3_origin_config {
        origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path}"
    }
  }

  enabled = true
  default_root_object = "${var.root_page_object}"
  aliases = ["${var.site_tld}", "www.${var.site_tld}"]
  price_class = "${var.cloudfront_price_class}"
  retain_on_delete = true
  default_cache_behavior {
    allowed_methods = [ "DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT" ]
    cached_methods = [ "GET", "HEAD" ]
    target_origin_id = "${var.site_tld}"
    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    compress = true
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
  }
  viewer_certificate {
    acm_certificate_arn = "${var.acm_site_certificate_arn}"
    ssl_support_method  = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# DNS entry pointing to public site - optional

# SNS to support notifications for commit and build events
resource "aws_sns_topic" "sns_topic" {
  count = "${var.create_sns_topic == "true" ? 1 : 0}"
  name = "${var.sns_topic_name}"
}
