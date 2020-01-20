# Hugo Static S3 Website Example

You can use this Terraform module to make a CodePipeline/CodeCommit/S3 static website with Hugo. Implement the Terraform module as specified in the root documentation, then provide these two buildspec files in the root of your CodeCommit repo. Your new CodePipeline will use them to execute steps to build and deploy your Hugo website into the static S3 bucket.

Note that you'll want to change the distribution ID and bucket name in the file "buildspec.yml" to match your settings.
