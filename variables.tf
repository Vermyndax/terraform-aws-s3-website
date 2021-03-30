# Creation flags first

variable "site_region" {
  type        = string
  description = "Region in which to provision the site. Default: us-east-1"
  default     = "us-east-1"
}

variable "create_www_redirect_bucket" {
  type        = bool
  description = "Defines whether or not to create a www redirect S3 bucket."
  default     = true
}

variable "content_bucket_versioning" {
  type        = bool
  description = "Defines whether or not to set versioning on the content bucket."
  default     = true
}

variable "create_cloudfront_distribution" {
  type        = bool
  description = "Defines whether or not to create a CloudFront distribution for the S3 bucket."
  default     = true
}

variable "log_include_cookies" {
  type        = bool
  description = "Defines whether or not CloudFront should log cookies."
  default     = false
}

variable "site_tld" {
  type        = string
  description = "TLD of the website you want to create. Example: example.com"
}

variable "site_hostname" {
  type        = string
  description = "Set this value if you want the site to have a name other than the TLD."
  default     = null
}

variable "create_public_dns_zone" {
  type        = bool
  description = "If set to true, creates a public hosted zone in Route53 for your site."
  default     = false
}

variable "create_public_dns_site_record" {
  type        = bool
  description = "If set to true, creates a public DNS record in your site_tld hosted zone. If you do not already have a hosted zone for this TLD, you should set create_public_dns_zone to true. Otherwise, this will try to create a record in an existing zone or fail."
  default     = true
}

variable "create_public_dns_www_record" {
  type        = bool
  description = "Defines whether or not to create a WWW DNS record for the site."
  default     = false
}

variable "root_page_object" {
  type        = string
  description = "The root page object for the Cloudfront/S3 distribution."
  default     = "index.html"
}

variable "error_page_object" {
  type        = string
  description = "The error page object for the Cloudfront/S3 distribution."
  default     = "404.html"
}

variable "cloudfront_price_class" {
  type        = string
  description = "Price class for Cloudfront."
  default     = "PriceClass_100"
}

variable "acm_site_certificate_arn" {
  type        = string
  description = "ARN of an ACM certificate to use for https on the CloudFront distribution."
}

variable "create_content_sync_user" {
  type        = bool
  description = "Optionally create an IAM user and access keys to sync the content bucket. Note that this will store access information in your state file. Protect it accordingly."
  default     = false
}
