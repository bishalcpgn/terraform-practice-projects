
variable "aws_region" {
  description = "Region for s3 bucket"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "name used as a prefix for resource"
  type        = string
  default     = "tfsite"
  nullable    = false

  # use validation with can(regex())
  # regex() - try this rule 
  # can() - did the rule succeed ? 
  # fails at plan time with a error_message
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,20}[a-z0-9]$", var.project))
    error_message = "project must be 3-22 lower alphanumeric/hyphen, can't start or end with hyphen"
  }
}
