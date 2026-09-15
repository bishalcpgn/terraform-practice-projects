# =============================================================================
# envs/dev/outputs.tf
# -----------------------------------------------------------------------------
# Root module outputs are printed after apply and readable via `terraform output`.
# They're for HUMANS and for scripts - surface what an operator actually needs.
#
# Note: unlike child modules, root outputs here omit `type`. You can add it,
# but the `deprecated` attribute is NOT allowed on root outputs (there is no
# caller to warn).
# =============================================================================

output "vpc_id" {
  description = "VPC created for this environment."
  value       = module.network.vpc_id
}

output "subnets_by_az" {
  description = "Subnet layout, keyed by availability zone."
  value       = module.network.subnets_by_az
}

output "app_security_group_id" {
  description = "Security group attached to the instances."
  value       = module.app_sg.security_group_id
}

output "instance_ids" {
  description = "Instance IDs keyed by name. Read with: terraform output -json instance_ids | jq"
  value       = module.app.instance_ids
}

output "connect" {
  description = "Run one of these to open a shell on an instance."
  value       = module.app.ssm_session_commands
}