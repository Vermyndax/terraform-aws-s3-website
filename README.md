# terraform-aws-s3-website

Terraform module that produces an S3 website plus supporting infrastructure for CD. This will deploy:

* S3 bucket for the website hosting
* S3 bucket for a www redirect
* S3 bucket for CodeDeploy artifacts
* An optional CodeCommit repo
* Supporting IAM roles
* CodeDeploy supporting projects
* CodePipeline for deploying to your S3 bucket from a git repo
* CloudFront distribution
* A DNS entry pointing to the whole mess (optional)

If you like it, please consider contributing.

## How to use this module

Info on how to call this module in your code.

## Variables

Variables will be described here.