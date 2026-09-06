# using cloudfront with oac

# OAC
# This is an identity, not a permission. It tells CloudFront: when you fetch
# from this origin, sign the request with SigV4 as the CloudFront service.
# S3 still has to be told to trust it, via the bucket policy.
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${var.name_prefix}-oac"
  description                       = "OAC for ${var.name_prefix} S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# using aws managed cache policy
data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  comment             = "${var.name_prefix} static site"
  default_root_object = var.default_root_object

  price_class = var.price_class

  wait_for_deployment = false

  origin {
    # MUST be the regional domain name.
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id = "s3-origin"

    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true

    cache_policy_id = data.aws_cloudfront_cache_policy.optimized.id
  }

  # Mandatory block, even when you're not restricting anything.
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    # Uses CloudFront's own *.cloudfront.net certificate. Free, instant,
    # no domain required.
    cloudfront_default_certificate = true
  }
}