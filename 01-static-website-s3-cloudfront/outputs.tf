output "bucket_name" {
  description = "Name of the origin bucket."
  value       = module.site.bucket_name
}

output "distribution_id" {
  description = "CloudFront distribution ID."
  value       = module.site.distribution_id
}

output "website_url" {
  description = "Public URL of the site."
  value       = module.site.website_url
}