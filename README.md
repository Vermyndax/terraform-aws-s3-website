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

````bash
openssl rand -base64 36
````

This will generate a random string of 36 characters. Supply this string for "site_secret" below. This secret will not be used to encrypt values, it merely sets up a secret between CloudFront and S3 to only accept traffic from CloudFront with a user-agent containing that string.

You'll integrate it into your existing Terraform stack by calling it with a module code block. It will look something like this the below chunk of code. This chunk of code creates a site for "example.com":

````json
module "example_site" {
    source = "github.com/vermyndax/terraform-aws-s3-website"
    create_www_redirect_bucket = "true"
    create_cloudfront_distribution = "true"
    site_github_owner = "<your-github-owner>"
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

## Providers

| Name | Version |
| ---- | ------- |
| aws  | n/a     |

## Inputs

| Name                              | Description                                                                                                                                                                                                                                                                 | Type     | Default                             | Required |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ----------------------------------- | :------: |
| acm\_site\_certificate\_arn       | ARN of an ACM certificate to use for https on the CloudFront distribution. Required.                                                                                                                                                                                        | `any`    | n/a                                 |   yes    |
| build\_compute\_type              | Build instance type to use for the CodeBuild project. Default: BUILD\_GENERAL1\_SMALL.                                                                                                                                                                                      | `string` | `"BUILD_GENERAL1_SMALL"`            |    no    |
| build\_image                      | Managed build image for CodeBuild. Default: aws/codebuild/ubuntu-base:14.04                                                                                                                                                                                                 | `string` | `"aws/codebuild/ubuntu-base:14.04"` |    no    |
| build\_privileged\_override       | Set the build privileged override to 'true' if you are not using a CodeBuild supported Docker base image. This is only relevant to building Docker images.                                                                                                                  | `string` | `"false"`                           |    no    |
| build\_timeout                    | Build timeout for the build stage (in minutes). Default: 5                                                                                                                                                                                                                  | `string` | `"5"`                               |    no    |
| cloudfront\_price\_class          | Price class for Cloudfront. Default: PriceClass\_100                                                                                                                                                                                                                        | `string` | `"PriceClass_100"`                  |    no    |
| codepipeline\_kms\_key\_arn       | The ARN of a KMS key to use with the CodePipeline and S3 artifacts bucket. If you do not specify an ARN, we'll create a KMS key for you and use it.                                                                                                                         | `string` | `""`                                |    no    |
| create\_cloudfront\_distribution  | Defines whether or not to create a CloudFront distribution for the S3 bucket. Default: true.                                                                                                                                                                                | `bool`   | `true`                              |    no    |
| create\_public\_dns\_site\_record | If set to true, creates a public DNS record in your site\_tld hosted zone. If you do not already have a hosted zone for this TLD, you should set create\_public\_dns\_zone to true. Otherwise, this will try to create a record in an existing zone or fail. Default: true. | `string` | `"true"`                            |    no    |
| create\_public\_dns\_www\_record  | Defines whether or not to create a WWW DNS record for the site. Default: false.                                                                                                                                                                                             | `bool`   | `false`                             |    no    |
| create\_public\_dns\_zone         | If set to true, creates a public hosted zone in Route53 for your site. Default: false.                                                                                                                                                                                      | `string` | `"false"`                           |    no    |
| create\_sns\_topic                | Defines whether or not to create an SNS topic for notifications about events. Default: true.                                                                                                                                                                                | `bool`   | `true`                              |    no    |
| create\_www\_redirect\_bucket     | Defines whether or not to create a www redirect S3 bucket. Default: true                                                                                                                                                                                                    | `bool`   | `true`                              |    no    |
| error\_page\_object               | The error page object for the Cloudfront/S3 distribution. Default: 404.html                                                                                                                                                                                                 | `string` | `"404.html"`                        |    no    |
| log\_include\_cookies             | Defines whether or not CloudFront should log cookies. Default: false.                                                                                                                                                                                                       | `bool`   | `false`                             |    no    |
| package\_buildspec                | The buildspec to be used for the Build stage (default: buildspec.yml). This file should exist in the root of your CodeCommit or Git repo.                                                                                                                                   | `string` | `"buildspec.yml"`                   |    no    |
| root\_page\_object                | The root page object for the Cloudfront/S3 distribution. Default: index.html                                                                                                                                                                                                | `string` | `"index.html"`                      |    no    |
| site\_region                      | Region in which to provision the site. Default: us-east-1                                                                                                                                                                                                                   | `string` | `"us-east-1"`                       |    no    |
| site\_secret                      | A secret to be used between S3 and CloudFront to manage web access. This will be put in the bucket policy and CloudFront distribution. Required.                                                                                                                            | `any`    | n/a                                 |   yes    |
| site\_tld                         | TLD of the website you want to create. A bucket will be created that is named this. Note that the module will error out if this bucket already exists in AWS. Example: example.com                                                                                          | `any`    | n/a                                 |   yes    |
| sns\_topic\_name                  | Name for the SNS topic.                                                                                                                                                                                                                                                     | `string` | `"website-notifications"`           |    no    |
| test\_buildspec                   | The buildspec to be used for the Test stage (default: buildspec\_test.yml). This file should exist in the root of your CodeCommit or Git repo.                                                                                                                              | `string` | `"buildspec_test.yml"`              |    no    |
| test\_compute\_type               | Build instance type to use for the CodeBuild project. Default: BUILD\_GENERAL1\_SMALL.                                                                                                                                                                                      | `string` | `"BUILD_GENERAL1_SMALL"`            |    no    |
| test\_image                       | Managed build image for CodeBuild. Default: aws/codebuild/ubuntu-base:14.04                                                                                                                                                                                                 | `string` | `"aws/codebuild/ubuntu-base:14.04"` |    no    |

## Outputs

| Name                               | Description |
| ---------------------------------- | ----------- |
| codecommit\_repo\_arn              | n/a         |
| codecommit\_repo\_clone\_url\_http | n/a         |
| codecommit\_repo\_clone\_url\_ssh  | n/a         |
| codecommit\_repo\_id               | n/a         |

## Hugo Website

I use this module to deploy Hugo websites with CodeCommit/CodePipeline in an S3 bucket. Consult the folder: "examples/hugo_website" for a peek at the buildspec.yml files I use to accomplish that.

## Author

Jason Miller - [jmiller@red-abstract.com](jmiller@red-abstract.com) - [http://galaxycow.com](http://galaxycow.com)

## LICENSE & Contributors

See LICENSE for license info. Contributions are welcome through pull requests.
