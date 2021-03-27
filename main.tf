# Terraform module to set up a full S3 publishing pipeline and supporting resources. See README.md for usage.
# Author: Jason Miller (jmiller@red-abstract.com) - https://galaxycow.com
# This project is used on https://galaxycow.com for a Hugo publishing workflow.
# Acknowledgements for code snippets:
# Secret idea/code from: https://github.com/ringods/terraform-website-s3-cloudfront-route53/blob/master/site-main/website_bucket_policy.json
# Support those authors and open source!

# TODO: Add more parameterization to CloudFront
# TODO: Add lifecycle policies to S3 buckets
locals {
  # site_codecommit_repo_name = var.codecommit_repo_name != "" ? var.codecommit_repo_name : var.site_tld
  site_tld_shortname = replace(var.site_tld, ".", "")
}

resource "random_uuid" "random_bucket_name" {
  # This will generate a random bucket name to avoid possible security issues.
}

resource "random_password" "random_site_secret" {
  length           = 32
  special          = true
  override_special = "_%@"
}

# S3 bucket for website, public hosting
resource "aws_s3_bucket" "main_site" {
  bucket = random_uuid.random_bucket_name.result
  # region = var.site_region

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
      "Resource": "arn:aws:s3:::${random_uuid.random_bucket_name.result}/*",
      "Principal": {
          "AWS":"*"
        },
      "Condition": {
        "StringEquals": {
          "aws:UserAgent": "${random_password.random_site_secret.result}"
        }
      }
    }
  ]
}
EOF


  website {
    index_document = var.root_page_object
    error_document = var.error_page_object
  }
  # tags {
  # }
  # force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "content_bucket_block" {
  bucket = aws_s3_bucket.main_site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# S3 bucket for www redirect (optional)
resource "aws_s3_bucket" "site_www_redirect" {
  count  = var.create_www_redirect_bucket == "true" ? 1 : 0
  bucket = "www.${random_uuid.random_bucket_name.result}"
  # region = var.site_region
  acl = "private"

  website {
    redirect_all_requests_to = var.site_tld
  }

  tags = {
    Website-redirect = var.site_tld
  }
}

# S3 bucket for CloudFront logging

data "aws_canonical_user_id" "current" {}

resource "aws_s3_bucket" "site_cloudfront_logs" {
  bucket = "${var.site_tld}-cloudfront-logs"
  # region = var.site_region
  # acl = "private"
  grant {
    id          = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0" # This is set by AWS, hope they never ever change it.
    type        = "CanonicalUser"
    permissions = ["FULL_CONTROL"]
  }

  grant {
    id          = data.aws_canonical_user_id.current.id
    type        = "CanonicalUser"
    permissions = ["FULL_CONTROL"]
  }
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs_block" {
  bucket = aws_s3_bucket.site_cloudfront_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "site_cloudfront_distribution" {
  origin {
    domain_name = aws_s3_bucket.main_site.website_endpoint
    origin_id   = "origin-bucket-${random_uuid.random_bucket_name.result}"

    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port              = "80"
      https_port             = "443"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    custom_header {
      name  = "User-Agent"
      value = random_password.random_site_secret.result
    }
  }

  logging_config {
    include_cookies = var.log_include_cookies
    bucket          = aws_s3_bucket.site_cloudfront_logs.bucket_domain_name
    prefix          = "${local.site_tld_shortname}-"
  }

  enabled             = true
  default_root_object = var.root_page_object
  aliases             = [var.site_tld, "www.${var.site_tld}"]
  price_class         = var.cloudfront_price_class
  retain_on_delete    = true

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "origin-bucket-${random_uuid.random_bucket_name.result}"

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_site_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# DNS entry pointing to public site - optional

resource "aws_route53_zone" "primary_site_tld" {
  count = var.create_public_dns_zone == "true" ? 1 : 0
  name  = var.site_tld
}

data "aws_route53_zone" "site_tld_selected" {
  name = "${var.site_tld}."
}

resource "aws_route53_record" "site_tld_record" {
  count   = var.create_public_dns_site_record == "true" ? 1 : 0
  zone_id = data.aws_route53_zone.site_tld_selected.zone_id
  name    = "${var.site_tld}."
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site_cloudfront_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.site_cloudfront_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "site_www_record" {
  count   = var.create_public_dns_www_record == "true" ? 1 : 0
  zone_id = data.aws_route53_zone.site_tld_selected.zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = "5"

  records = [var.site_tld]
}

