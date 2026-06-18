terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

}

resource "random_pet" "server" {
  length    = 3
  separator = "-"
}

resource "local_file" "server_name" {
  content  = random_pet.server.id
  filename = "${path.module}/server_name.txt"
}

resource "null_resource" "example" {
  depends_on = [local_file.server_name]
  triggers = {
    server_name = random_pet.server.id
  }
}

resource "random_id" "rotating" {
  byte_length = 8
  keepers = {
    server_name = random_pet.server.id
  }
  lifecycle {
    create_before_destroy = true
  }
}