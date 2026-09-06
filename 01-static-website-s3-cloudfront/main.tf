module "site" {
  source = "./modules/static-site"

  name_prefix = var.project

  force_destroy = true #sandbox only
}