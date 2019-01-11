# terraform-aws-s3-website

Terraform module that produces an S3 website plus supporting infrastructure for CD. This will deploy:

* S3 bucket for the website hosting
* S3 bucket for a www redirect
* S3 bucket for CodeDeploy artifacts
* S3 bucket for CloudFront logging
* An optional CodeCommit repo
* Supporting IAM roles
* CodeBuild supporting projects
* CodePipeline for deploying to your S3 bucket from a git repo
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

Next, create a secret that will be used between CloudFront and S3 to accept traffic. You can use openssl to generate a random secret for you like this:

````
openssl rand -base64 36
````

This will generate a random string of 36 characters. Supply this string for "site_secret" below. This secret will not be used to encrypt values, it merely sets up a secret between CloudFront and S3 to only accept traffic from CloudFront with a user-agent containing that string.

You'll integrate it into your existing Terraform stack by calling it with a module code block. It will look something like this the below chunk of code. This chunk of code creates a site for "example.com":

````
module "example_site" {
    source = "github.com/vermyndax/terraform-aws-s3-website"
    create_codecommit_repo = "true"
    create_www_redirect_bucket = "true"
    create_cloudfront_distribution = "true"
    site_tld = "example.com"
    create_sns_topic = "true"
    sns_topic_name = "example-pipeline-notifications"
    acm_site_certificate_arn = "arn:aws:acm:us-east-1:111111111111:certificate/00000000-0000-0000-0000-000000000000"
    site_secret = "asdiojasiopdjsajdasasdasdsadj"
    build_image = "aws/codebuild/eb-python-3.4-amazonlinux-64:2.1.6"
    create_public_dns_zone = "false"
    create_public_dns_site_record = "true"
    create_public_dns_www_record = "true"
}
````

## Variables

Some variables are required and do not have default values. Those variables must be filled in by you. Otherwise, you can accept the default values if they meet your needs.

| Variable                       | Description                                                                                                                                                                                                                                              | Required | Initial value                   |
|--------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|---------------------------------|
| site_region                    | Region in which to provision the site.                                                                                                                                                                                                                   | Yes      | us-east-1                       |
| create_www_redirect_bucket     | Defines whether or not to create a www redirect S3 bucket                                                                                                                                                                                                | Yes      | true                            |
| create_codecommit_repo         | Defines whether or not to create a CodeCommit repo. Default: true. NOTE: If you choose false, early versions of this module likely require that you fork and modify the code to point the CodeDeploy/CodePipeline stuff to your own repo.                | Yes      | true                            |
| create_cloudfront_distribution | Defines whether or not to create a CloudFront distribution for the S3 bucket.                                                                                                                                                                            | Yes      | true                            |
| log_include_cookies            | Defines whether or not CloudFront should log cookies.                                                                                                                                                                                                    | Yes      | false                           |
| create_sns_topic               | Defines whether or not to create an SNS topic for notifications about events.                                                                                                                                                                            | Yes      | true                            |
| sns_topic_name                 | Name for the SNS topic                                                                                                                                                                                                                                   | No       | website-notifications           |
| site_tld                       | TLD of the website you want to create. A bucket will be created that is named this. Note that the module will error out if this bucket already exists in AWS. Example: example.com                                                                       | Yes      | (empty)                         |
| create_public_dns_zone         | If set to true, creates a public hosted zone in Route53 for your site.                                                                                                                                                                                   | Yes      | false                           |
| create_public_dns_site_record  | If set to true, creates a public DNS record in your site_tld hosted zone. If you do not already have a hosted zone for this TLD, you should set create_public_dns_zone to true. Otherwise, this will try to create a record in an existing zone or fail. | Yes      | true                            |
| create_public_dns_www_record   | Defines whether or not to create a WWW DNS record for the site.                                                                                                                                                                                          | Yes      | false                           |
| site_secret                    | A secret to be used between S3 and CloudFront to manage web access. This will be put in the bucket policy and CloudFront distribution. Required.                                                                                                         | Yes      | (empty)                         |
| codepipeline_kms_key_arn       | The ARN of a KMS key to use with the CodePipeline and S3 artifacts bucket. If you do not specify an ARN, we'll create a KMS key for you and use it.                                                                                                      | No       | (empty)                         |
| codecommit_repo_name           | CodeCommit repo name. If this is defined, it will be created with this name. If you do not define it, we'll create one that matches the name of site_tld variable.                                                                                       | No       | (empty)                         |
| build_timeout                  | Build timeout for the build stage (in minutes).                                                                                                                                                                                                          | Yes      | 5                               |
| build_compute_type             | Build instance type to use for the CodeBuild project.                                                                                                                                                                                                    | Yes      | BUILD_GENERAL1_SMALL            |
| build_image                    | Managed build image for CodeBuild.                                                                                                                                                                                                                       | Yes      | aws/codebuild/ubuntu-base:14.04 |
| test_compute_type              | Build instance type to use for the CodeBuild project.                                                                                                                                                                                                    | Yes      | BUILD_GENERAL1_SMALL            |
| test_image                     | Managed build image for CodeBuild.                                                                                                                                                                                                                       | Yes      | aws/codebuild/ubuntu-base:14.04 |
| build_privileged_override      | Set the build privileged override to true if you are not using a CodeBuild supported Docker base image. This is only relevant to building Docker images.                                                                                                 | Yes      | false                           |
| test_buildspec                 | The buildspec to be used for the Test stage (default: buildspec_test.yml). This file should exist in the root of your CodeCommit or Git repo.                                                                                                            | Yes      | buildspec_test.yml              |
| package_buildspec              | The buildspec to be used for the Build stage (default: buildspec.yml). This file should exist in the root of your CodeCommit or Git repo.                                                                                                                | Yes      | buildspec.yml                   |
| root_page_object               | The root page object for the Cloudfront/S3 distribution.                                                                                                                                                                                                 | Yes      | index.html                      |
| error_page_object              | The error page object for the Cloudfront/S3 distribution.                                                                                                                                                                                                | Yes      | 404.html                        |
| cloudfront_price_class         | Price class for CloudFront.                                                                                                                                                                                                                              | Yes      | PriceClass_100                  |
| acm_site_certificate_arn       | ARN of an ACM certificate to use for https on the CloudFront distribution.                                                                                                                                                                               | Yes      | (empty)                         |

## Author

Jason Miller - [jmiller@red-abstract.com](jmiller@red-abstract.com) - [http://galaxycow.com](http://galaxycow.com)

## LICENSE & Contributors

See LICENSE for license info. Contributions are welcome through pull requests.