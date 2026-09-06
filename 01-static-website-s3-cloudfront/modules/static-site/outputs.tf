output "bucket_name" {
  description = "Name of the origin bucket."
  value       = aws_s3_bucket.site.id
}

output "distribution_id" {
  description = "CloudFront distribution ID, for cache invalidation."
  value       = aws_cloudfront_distribution.site.id
}

output "website_url" {
  description = "Public URL of the site."
  value       = "https://${aws_cloudfront_distribution.site.domain_name}/"
}