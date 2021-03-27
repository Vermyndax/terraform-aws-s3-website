output "content_sync_access_key" {
  value       = var.create_content_sync_user ? aws_iam_access_key.content_sync_key[0].id : ""
  description = "Access key ID of the optional content sync user."
}

output "content_sync_access_secret" {
  value       = var.create_content_sync_user ? aws_iam_access_key.content_sync_key[0].secret : ""
  sensitive   = true
  description = "Secret Access key of the optional content sync user. This is marked as sensitive and will not show in plan output, but be aware that it is stored in your state file. Encrypt accordingly."
}

output "content_sync_bucket_name" {
  value       = random_uuid.random_bucket_name.result
  description = "Bucket name that contains the content for the site."
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.site_cloudfront_distribution.id
  description = "CloudFront distribution ID."
}
