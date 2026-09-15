# =============================================================================
# envs/dev/versions.tf
# -----------------------------------------------------------------------------
# This is a ROOT MODULE - the directory you actually run `terraform apply` in.
#
# Root modules own three things that child modules must NEVER declare:
#   1. the backend (where state is stored)
#   2. the provider configuration (see providers.tf)
#   3. narrow version pins
# =============================================================================

terraform {
  required_version = ">= 1.15.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"

      # The ROOT module PINS. Child modules declared ">= 6.0.0, < 7.0.0";
      # this is where it gets decided which 6.x everyone actually gets.
      #
      # "~> 6.64" means >= 6.64.0 and < 7.0.0 (allows new minor versions).
      # "~> 6.64.0" would mean >= 6.64.0 and < 6.65.0 (patches only) - use that
      # form in production where you want tighter control.
      version = "~> 6.64"
    }
  }

  # ---------------------------------------------------------------------------
  # REMOTE STATE (commented out - start with local state, migrate later)
  #
  # Local state is fine for a solo lab and unacceptable for a team: it can't be
  # shared, isn't locked, isn't backed up, and contains everything Terraform
  # knows - including values you'd consider sensitive.
  #
  # To enable: create the bucket (see README), uncomment, then run
  #   terraform init -migrate-state
  # ---------------------------------------------------------------------------
  # backend "s3" {
  #   bucket = "tf-lab-state-<your-account-id>"
  #
  #   # Each environment MUST have a different key, or dev and prod-like share
  #   # one state file and destroy each other. This mistake happens for real.
  #   key    = "02-vpc-modules-aws/dev/terraform.tfstate"
  #
  #   region  = "us-east-1"
  #   encrypt = true
  #
  #   # Native S3 state locking, Terraform 1.10+. Locking used to require a
  #   # separate DynamoDB table you had to create, pay for and grant access to.
  #   # Now S3 writes a .tflock object next to the state file.
  #   # The old `dynamodb_table` argument still works but is DEPRECATED - if a
  #   # tutorial tells you to make a DynamoDB table, that tutorial is outdated.
  #   use_lockfile = true
  # }
}