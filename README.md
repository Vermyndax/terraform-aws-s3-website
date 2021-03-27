# terraform-aws-s3-website

[![Terraform CI](https://github.com/Vermyndax/terraform-aws-s3-website/workflows/Terraform%20CI/badge.svg)](https://github.com/Vermyndax/terraform-aws-s3-website/actions?query=workflow%3A%22Terraform+CI%22)

## Changelog

### 03/22/21

* Added a public access block for the CloudFront logging bucket.
* Updated to TLSv1.2_2019 on CloudFront distribution.
* Fix adding canonical ID for CloudFront logging on the bucket.

### 03/20/21

* Did a pretty massive refactoring of this module. If you used this module in the past to deploy CodePipeline stuff, DO NOT USE THIS RELEASE.
* Lots of resources removed and simplified. Note that we no longer create the name of the bucket to match the site TLD. Now, we generate a random UUID and name the bucket with the result. This is because it's far too easy to take over an S3 website served from an S3 bucket if you know the website address.
* Code* resources have been removed because there are far too many CI/CD approaches in the market today. I myself am moving to GitHub Actions for everything. I decided it was a better idea to rip out all of the supporting CI/CD stuff and assume you have something in place. Not to mention, KMS keys cost more than they should.

Terraform module that produces an S3 website plus supporting infrastructure for CD. This will deploy:

* S3 bucket for the website hosting
* S3 bucket for a www redirect
* CloudFront distribution
* A top-level zone for DNS (optional)
* DNS entries pointing to the whole mess (optional)
* SNS Topic for notifications on these resources (you'll have to manually add your own subscriptions)
* KMS Key for encryption where supported, or it will configure one
* Deploy an existing Amazon Certificate Manager SSL certificate (required for you to create ahead of time)

If you like it, please consider contributing.

## How to use this module

Before you get started, you'll need a few things that are outside the scope of this module. You will need:

* A way to deploy Terraform in your environment
* An Amazon Certificate Manager certificate
* Proper IAM permissions to deploy resources in your environment either with your IAM account or a role, depending on how you deploy Terraform
* A random string of characters for a shared secret between CloudFront and S3

First, create your Amazon certificate using the normal process. Note down the ARN and supply it for the variable "acm_site_certificate_arn" below.

This chunk of code creates a site for "example.com":

````json
module "example_site" {
    source = "github.com/vermyndax/terraform-aws-s3-website"
    create_www_redirect_bucket = "true"
    create_cloudfront_distribution = "true"
    site_github_owner = "<your-github-owner>"
    site_tld = "example.com"
    acm_site_certificate_arn = "arn:aws:acm:us-east-1:111111111111:certificate/00000000-0000-0000-0000-000000000000"
    create_public_dns_zone = "false"
    create_public_dns_site_record = "true"
    create_public_dns_www_record = "true"
}
````

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 0.14.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_distribution.site_cloudfront_distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_route53_record.site_tld_record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.site_www_record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.primary_site_tld](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_s3_bucket.main_site](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.site_cloudfront_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.site_www_redirect](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.cloudfront_logs_block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.content_bucket_block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [random_password.random_site_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_uuid.random_bucket_name](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) | resource |
| [aws_canonical_user_id.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/canonical_user_id) | data source |
| [aws_route53_zone.site_tld_selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_site_certificate_arn"></a> [acm\_site\_certificate\_arn](#input\_acm\_site\_certificate\_arn) | ARN of an ACM certificate to use for https on the CloudFront distribution. | `any` | n/a | yes |
| <a name="input_cloudfront_price_class"></a> [cloudfront\_price\_class](#input\_cloudfront\_price\_class) | Price class for Cloudfront. | `string` | `"PriceClass_100"` | no |
| <a name="input_content_bucket_versioning"></a> [content\_bucket\_versioning](#input\_content\_bucket\_versioning) | Defines whether or not to set versioning on the content bucket. | `bool` | `true` | no |
| <a name="input_create_cloudfront_distribution"></a> [create\_cloudfront\_distribution](#input\_create\_cloudfront\_distribution) | Defines whether or not to create a CloudFront distribution for the S3 bucket. | `bool` | `true` | no |
| <a name="input_create_public_dns_site_record"></a> [create\_public\_dns\_site\_record](#input\_create\_public\_dns\_site\_record) | If set to true, creates a public DNS record in your site\_tld hosted zone. If you do not already have a hosted zone for this TLD, you should set create\_public\_dns\_zone to true. Otherwise, this will try to create a record in an existing zone or fail. | `string` | `"true"` | no |
| <a name="input_create_public_dns_www_record"></a> [create\_public\_dns\_www\_record](#input\_create\_public\_dns\_www\_record) | Defines whether or not to create a WWW DNS record for the site. | `bool` | `false` | no |
| <a name="input_create_public_dns_zone"></a> [create\_public\_dns\_zone](#input\_create\_public\_dns\_zone) | If set to true, creates a public hosted zone in Route53 for your site. | `string` | `"false"` | no |
| <a name="input_create_sns_topic"></a> [create\_sns\_topic](#input\_create\_sns\_topic) | Defines whether or not to create an SNS topic for notifications about events. | `bool` | `false` | no |
| <a name="input_create_www_redirect_bucket"></a> [create\_www\_redirect\_bucket](#input\_create\_www\_redirect\_bucket) | Defines whether or not to create a www redirect S3 bucket. | `bool` | `true` | no |
| <a name="input_error_page_object"></a> [error\_page\_object](#input\_error\_page\_object) | The error page object for the Cloudfront/S3 distribution. | `string` | `"404.html"` | no |
| <a name="input_log_include_cookies"></a> [log\_include\_cookies](#input\_log\_include\_cookies) | Defines whether or not CloudFront should log cookies. | `bool` | `false` | no |
| <a name="input_root_page_object"></a> [root\_page\_object](#input\_root\_page\_object) | The root page object for the Cloudfront/S3 distribution. | `string` | `"index.html"` | no |
| <a name="input_site_region"></a> [site\_region](#input\_site\_region) | Region in which to provision the site. Default: us-east-1 | `string` | `"us-east-1"` | no |
| <a name="input_site_tld"></a> [site\_tld](#input\_site\_tld) | TLD of the website you want to create. A bucket will be created that is named this. Note that the module will error out if this bucket already exists in AWS. Example: example.com | `any` | n/a | yes |
| <a name="input_sns_topic_name"></a> [sns\_topic\_name](#input\_sns\_topic\_name) | Name for the SNS topic. | `string` | `"website-notifications"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->