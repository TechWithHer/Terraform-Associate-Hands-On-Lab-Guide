terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~>3.6"
    }
  }
}

resource "random_integer" "port_no" {
  min = 1024
  max = 65535
}
