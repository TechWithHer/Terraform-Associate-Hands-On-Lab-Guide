terraform {
  required_providers {
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }
}

# Local module via relative path
module "alpha" {
  source  = "./modules/filemaker"
  name    = "alpha"
  content = "I came from a module."
}

module "beta" {
  source  = "./modules/filemaker"
  name    = "beta"
}

# Registry module (versioned) — sourced from the public Terraform Registry
# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "~> 5.0"        # 5d: version pinning ONLY works with the registry/git source
# }

output "alpha_path" { value = module.alpha.path } # 5c: consume child module output
