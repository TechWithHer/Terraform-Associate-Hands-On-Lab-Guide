terraform {
  required_providers {
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

# 1) Input variable validation
variable "instance_count" {
  type    = number
  default = 3
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "instance_count must be between 1 and 10."
  }
}

variable "env" {
  type    = string
  default = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "env must be one of dev, staging, prod."
  }
}

resource "random_integer" "r" {
  min = 1
  max = var.instance_count

  # 2) Precondition: checked BEFORE the resource is created/updated
  lifecycle {
    precondition {
      condition     = var.instance_count >= 1
      error_message = "Need at least one instance to pick a random integer."
    }
    # 3) Postcondition: checked AFTER, validates the result
    postcondition {
      condition     = self.result <= var.instance_count
      error_message = "Result exceeded the allowed maximum."
    }
  }
}

# 4) check block: continuous, non-blocking assertions (warns, does not fail apply)
check "sanity" {
  assert {
    condition     = var.instance_count <= 10
    error_message = "instance_count is unusually high."
  }
}
