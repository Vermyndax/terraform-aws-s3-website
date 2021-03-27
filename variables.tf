# Creation flags first

variable "site_region" {
  description = "Region in which to provision the site. Default: us-east-1"
  default     = "us-east-1"
}

variable "create_www_redirect_bucket" {
  description = "Defines whether or not to create a www redirect S3 bucket."
  default     = true
}

variable "content_bucket_versioning" {
  description = "Defines whether or not to set versioning on the content bucket."
  default     = true
}

variable "create_cloudfront_distribution" {
  description = "Defines whether or not to create a CloudFront distribution for the S3 bucket."
  default     = true
}

variable "log_include_cookies" {
  description = "Defines whether or not CloudFront should log cookies."
  default     = false
}

variable "create_sns_topic" {
  description = "Defines whether or not to create an SNS topic for notifications about events."
  default     = false
}

variable "sns_topic_name" {
  description = "Name for the SNS topic."
  default     = "website-notifications"
}

variable "site_tld" {
  description = "TLD of the website you want to create. A bucket will be created that is named this. Note that the module will error out if this bucket already exists in AWS. Example: example.com"
}

variable "create_public_dns_zone" {
  description = "If set to true, creates a public hosted zone in Route53 for your site."
  default     = "false"
}

variable "create_public_dns_site_record" {
  description = "If set to true, creates a public DNS record in your site_tld hosted zone. If you do not already have a hosted zone for this TLD, you should set create_public_dns_zone to true. Otherwise, this will try to create a record in an existing zone or fail."
  default     = "true"
}

variable "create_public_dns_www_record" {
  description = "Defines whether or not to create a WWW DNS record for the site."
  default     = false
}

variable "root_page_object" {
  description = "The root page object for the Cloudfront/S3 distribution."
  default     = "index.html"
}

variable "error_page_object" {
  description = "The error page object for the Cloudfront/S3 distribution."
  default     = "404.html"
}

variable "cloudfront_price_class" {
  description = "Price class for Cloudfront."
  default     = "PriceClass_100"
}

variable "acm_site_certificate_arn" {
  description = "ARN of an ACM certificate to use for https on the CloudFront distribution."
}

variable "create_content_sync_user" {
  type        = bool
  description = "Optionally create an IAM user and access keys to sync the content bucket. Note that this will store access information in your state file. Protect it accordingly."
  default     = false
}
