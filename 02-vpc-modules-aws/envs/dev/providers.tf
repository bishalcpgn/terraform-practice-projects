# =============================================================================
# envs/dev/providers.tf
# -----------------------------------------------------------------------------
# Provider configuration belongs ONLY in the root module.
#
# A child module with its own provider block cannot be used with for_each or
# count, and is very painful to remove later. Child modules simply inherit
# whatever the root configured.
# =============================================================================

provider "aws" {
  region = var.region

  # ###########################################################################
  # NOTE: there are NO credentials here, and there never should be.
  #
  # The provider picks them up automatically from (in order): environment
  # variables, ~/.aws/credentials, AWS SSO, or an instance role.
  # If you ever see `access_key` in a .tf file, that is a security finding.
  # ###########################################################################

  # default_tags applies these to EVERY taggable resource this provider creates,
  # including resources inside child modules. One block, whole-estate coverage -
  # no need to thread a tags variable through every module.
  #
  # You cannot manage what you cannot find. Tag from day one.
  default_tags {
    tags = {
      Project   = "02-vpc-modules-aws"
      Env       = var.environment
      ManagedBy = "terraform"
      Owner     = var.owner
    }
  }
}