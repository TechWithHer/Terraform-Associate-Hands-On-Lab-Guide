terraform {
  required_providers {
    random = {
      source = "hashicorp/random",
    version = "~>3.6" }
    local = {
      source = "hashicorp/local",
    version = "~>2.5" }
  }
}
variable "api_token" {
  type      = string
  sensitive = true
}

resource "random_password" "db" {
  length    = 20
  special = true
}

resource "local_sensitive_file" "secret" {
  filename = "${path.module}/secret.txt"
  content  = "token=${var.api_token}\ndb=${random_password.db.result}\n"
}
output "db_password" {
  value     = random_password.db.result
  sensitive = true
}


