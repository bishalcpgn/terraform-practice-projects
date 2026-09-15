# =============================================================================
# envs/dev/main.tf
# -----------------------------------------------------------------------------
# The root module's job is WIRING and DECISIONS: which modules to call, with
# what values, for this environment. It creates almost no resources itself.
#
# Terraform builds the dependency graph automatically from the references
# between modules, which is why there is no depends_on anywhere in this file:
#   app_sg needs network.vpc_id              -> network runs first
#   app    needs app_sg.security_group_id    -> app_sg runs before app
# =============================================================================

locals {
  # One place to change the naming scheme for everything in this environment.
  name = "tf-lab-${var.environment}" # e.g. "tf-lab-dev"

  tags = {
    Lab = "02-vpc-modules-aws"
  }
}

# -----------------------------------------------------------------------------
# MODULE 1: network
# -----------------------------------------------------------------------------
module "network" {
  # A relative path. Terraform COPIES local modules into .terraform/modules/
  # at init time - so after editing anything under modules/, you must re-run
  # `terraform init` or your change is silently ignored. This trips up everyone once.
  source = "../../modules/network"

  name     = local.name
  vpc_cidr = var.vpc_cidr
  az_count = var.az_count

  enable_ssm_endpoints = var.enable_ssm_endpoints
  enable_nat_gateway   = false # VPC endpoints are cheaper for SSM-only traffic

  # We only override ONE attribute of the subnets object. The other three
  # (newbits, public_offset, private_offset) fall back to their optional()
  # defaults inside the module. That's the whole point of optional().
  subnets = {
    map_public_ip = var.placement == "public"
  }

  tags = local.tags
}

# -----------------------------------------------------------------------------
# MODULE 2: security
# -----------------------------------------------------------------------------
module "app_sg" {
  source = "../../modules/security"

  name        = "${local.name}-app"
  description = "Application instances. No inbound rules by design; access is via Session Manager."

  # Reading an OUTPUT of another module. This reference is also what tells
  # Terraform that network must be created before this module.
  vpc_id = module.network.vpc_id

  rules = {
    # #########################################################################
    # NOTE WHAT IS ABSENT: there is no ingress rule. Not one.
    #
    # SSM Agent makes an OUTBOUND connection and AWS brokers the session, so
    # nothing ever needs to connect inbound. This is the entire security story
    # of the lab, and it is expressed by an omission.
    # #########################################################################

    "https-out" = {
      description = "HTTPS out - SSM Agent, package repos, VPC endpoints"
      type        = "egress"
      ip_protocol = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_ipv4   = "0.0.0.0/0"
    }

    "http-out" = {
      description = "HTTP out - dnf package metadata"
      type        = "egress"
      ip_protocol = "tcp"
      from_port   = 80
      to_port     = 80
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  tags = local.tags
}

# -----------------------------------------------------------------------------
# MODULE 3: compute
# -----------------------------------------------------------------------------

locals {
  # THE one line that differentiates dev from prod-like. Everything else about
  # the two environments is identical configuration with different .tfvars.
  target_subnet_ids = var.placement == "public" ? module.network.public_subnet_ids : module.network.private_subnet_ids
}

module "app" {
  source = "../../modules/compute"

  name = "${local.name}-app"

  # Build the instances map programmatically.
  #
  #   range(2)                -> [0, 1]
  #   format("app-%02d", 1)   -> "app-01"   (%02d = zero-padded to 2 digits)
  #   element(list, i)        -> list[i], but WRAPS AROUND at the end
  #
  # element() wrapping gives round-robin placement: with 3 instances and 2
  # subnets you get subnets [0], [1], [0]. Plain indexing would fail on the third.
  instances = {
    for i in range(var.instance_count) :
    format("app-%02d", i + 1) => {
      subnet_id           = element(local.target_subnet_ids, i)
      instance_type       = var.instance_type
      associate_public_ip = var.placement == "public"
      extra_tags          = { Role = "demo-app" }
    }
  }

  security_group_ids = [module.app_sg.security_group_id]

  tags = local.tags
}

# -----------------------------------------------------------------------------
# GUARDRAILS - `check` blocks
#
# IMPORTANT DISTINCTION:
#   precondition  -> FAILS the apply. Use for "this config is invalid".
#   check         -> WARNS but lets the apply finish. Use for "is it healthy?".
#
# You don't want a transient health status to block a deploy, but you do want
# it shouted at you. check blocks may also declare their own scoped data
# sources, which keeps them out of your main dependency graph.
# -----------------------------------------------------------------------------

check "ssm_is_reachable" {
  assert {
    # A private instance with no endpoints and no NAT can never reach Systems
    # Manager. Terraform would happily build it; you'd just never connect.
    # Catching it here saves a confusing 20 minutes of debugging.
    condition     = var.placement == "public" || var.enable_ssm_endpoints
    error_message = "Instances in private subnets need interface VPC endpoints (or a NAT gateway), otherwise Session Manager will never connect. Set enable_ssm_endpoints = true."
  }
}

check "instances_are_running" {
  # A data source scoped to this check only. It reads live AWS state after apply.
  data "aws_instance" "first" {
    instance_id = module.app.instance_ids["app-01"]
  }

  assert {
    condition     = data.aws_instance.first.instance_state == "running"
    error_message = "app-01 is ${data.aws_instance.first.instance_state}, not running. Check the console before trying to connect."
  }
}