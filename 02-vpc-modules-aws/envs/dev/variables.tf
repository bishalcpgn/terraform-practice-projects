# =============================================================================
# envs/dev/variables.tf
# -----------------------------------------------------------------------------
# Root module variables are the knobs an OPERATOR turns. They're deliberately
# higher-level than the module variables they feed: "placement = private"
# rather than six separate low-level settings.
# =============================================================================

variable "region" {
  description = "AWS region for this environment."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name. Becomes part of every resource name."
  type        = string
  default     = "dev"

  validation {
    # contains(list, value) - a simple allow-list. Stops "Dev", "develop",
    # "dev2" and other near-misses from creating a parallel set of resources.
    condition     = contains(["dev", "staging", "prod-like"], var.environment)
    error_message = "environment must be one of: dev, staging, prod-like."
  }
}

variable "owner" {
  description = "Who to contact about this stack. Shows up in default_tags."
  type        = string
  # No default -> REQUIRED. You must set this in terraform.tfvars.
  # Deliberate: an untagged, unowned stack is how cloud bills get out of hand.
}

variable "vpc_cidr" {
  description = "IPv4 CIDR for the VPC. Must not overlap with other environments."
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use."
  type        = number
  default     = 2
}

variable "placement" {
  description = <<-EOT
    Where the instances live. This single switch is what differentiates the two
    environments in this lab.

    "public"  - public subnets, public IP, reaches SSM via the internet gateway.
                Cheapest. Still has ZERO inbound security group rules.
    "private" - private subnets, no public IP, no internet route at all.
                Reaches SSM via interface VPC endpoints. Production-shaped.
  EOT
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "private"], var.placement)
    error_message = "placement must be \"public\" or \"private\"."
  }
}

variable "instance_count" {
  description = "How many instances to launch, spread round-robin across AZs."
  type        = number
  default     = 1

  validation {
    # A lab guard rail: stops a stray zero turning into a 40-instance bill.
    condition     = var.instance_count >= 1 && var.instance_count <= 4
    error_message = "Keep instance_count between 1 and 4 in this lab."
  }
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "enable_ssm_endpoints" {
  description = "Create interface VPC endpoints. REQUIRED when placement = \"private\", otherwise Session Manager can never connect. ~USD 0.04/hour with two AZs."
  type        = bool
  default     = false
}