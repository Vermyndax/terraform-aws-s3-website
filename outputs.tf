output "content_sync_access_key" {
  count       = var.create_content_sync_user == true ? 1 : 0
  value       = aws_iam_access_key.content_sync_key[0].id
  description = "Access key ID of the optional content sync user."
}

output "content_sync_access_secret" {
  count       = var.create_content_sync_user == true ? 1 : 0
  value       = aws_iam_access_key.content_sync_key[0].secret
  sensitive   = true
  description = "Secret Access key of the optional content sync user. This is marked as sensitive and will not show in plan output, but be aware that it is stored in your state file. Encrypt accordingly."
}
