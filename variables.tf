# Creation flags first

variable "site_region" {
    description = "Region in which to provision the site. Default: us-east-1"
    default = "us-east-1"
}

variable "create_www_redirect_bucket" {
    description = "Defines whether or not to create a www redirect S3 bucket. Default: true"
    default = true
}

variable "create_dns_hosted_zone" {
    description = "Defines whether or not to create a hosted zone. Default: false."
    default = false
}

variable "create_dns_record" {
    description = "Defines whether or not to create DNS records for the site. Default: false."
    default = false
}

variable "create_codecommit_repo" {
    description = "Defines whether or not to create a CodeCommit repo. Default: true. NOTE: If you choose false, early versions of this module likely require that you fork and modify the code to point the CodeDeploy/CodePipeline stuff to your own repo."
    default = true
}

variable "create_cloudfront_distribution" {
    description = "Defines whether or not to create a CloudFront distribution for the S3 bucket. Default: true."
    default = true
}

variable "create_sns_topic" {
    description = "Defines whether or not to create an SNS topic for notifications about events. Default: true."
    default = true
}

variable "sns_topic_name" {
    description = "Name for the SNS topic."
    default = "website-notifications"
}

variable "site_tld" {
    description = "TLD of the website you want to create. A bucket will be created that is named this. Note that the module will error out if this bucket already exists in AWS. Example: example.com"
}

variable "site_secret" {
    description = "A secret to be used between S3 and CloudFront to manage web access. This will be put in the bucket policy and CloudFront distribution. Required."
}

variable "codepipeline_kms_key_arn" {
    description = "The ARN of a KMS key to use with the CodePipeline and S3 artifacts bucket. If you do not specify an ARN, we'll create a KMS key for you and use it."
    default = ""
}

variable "codecommit_repo_name" {
    description = "CodeCommit repo name. If this is defined, it will be created with this name. If you do not define it, we'll create one that matches the name of site_tld variable."
    default = ""
}

variable "build_timeout" {
    description = "Build timeout for the build stage (in minutes). Default: 5"
    default = "5"
}

variable "build_compute_type" {
    description = "Build instance type to use for the CodeBuild project. Default: BUILD_GENERAL1_SMALL."
    default = "BUILD_GENERAL1_SMALL"
}

variable "build_image" {
    description = "Managed build image for CodeBuild. Default: aws/codebuild/ubuntu-base:14.04"
    default = "aws/codebuild/ubuntu-base:14.04"
}

variable "build_privileged_override" {
  description = "Set the build privileged override to 'true' if you are not using a CodeBuild supported Docker base image. This is only relevant to building Docker images."
  default     = "false"
}

variable "test_buildspec" {
  description = "The buildspec to be used for the Test stage (default: buildspec_test.yml). This file should exist in the root of your CodeCommit or Git repo."
  default     = "buildspec_test.yml"
}

variable "package_buildspec" {
  description = "The buildspec to be used for the Build stage (default: buildspec.yml). This file should exist in the root of your CodeCommit or Git repo."
  default     = "buildspec.yml"
}

variable "root_page_object" {
    description = "The root page object for the Cloudfront/S3 distribution. Default: index.html"
    default = "index.html"
}

variable "error_page_object" {
    description = "The error page object for the Cloudfront/S3 distribution. Default: 404.html"
    default = "404.html"
}

variable "cloudfront_price_class" {
    description = "Price class for Cloudfront. Default: PriceClass_100"
    default = "PriceClass_100"
}

variable "acm_site_certificate_arn" {
    description = "ARN of an ACM certificate to use for https on the CloudFront distribution. Required."
}

# TODO: Support names for the rest of the resources?