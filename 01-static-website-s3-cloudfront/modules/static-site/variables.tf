variable "name_prefix" {
  description = "Prefix for all resource names. Must be globally-safe for S3 naming."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,20}[a-z0-9]$", var.name_prefix))
    error_message = "name_prefix must be 3-22 lowercase alphanumeric or hyphen chars, not starting or ending with a hyphen."
  }
}

variable "default_root_object" {
  description = "Object CloudFront serves for requests to /."
  type        = string
  default     = "index.html"
}

variable "price_class" {
  description = "CloudFront edge coverage. PriceClass_100 is cheapest (NA + EU)."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "Must be one of: PriceClass_All, PriceClass_200, PriceClass_100."
  }
}

variable "force_destroy" {
  description = "Allow terraform destroy to remove a non-empty bucket. Never true in production."
  type        = bool
  default     = false
}

variable "noncurrent_version_expiration_days" {
  description = "Days before noncurrent object versions are permanently deleted."
  type        = number
  default     = 7

  validation {
    condition     = var.noncurrent_version_expiration_days >= 1
    error_message = "Must be at least 1 day."
  }
}