terraform {
    required_version = ">= 1.6.0"
    required_providers {
        local = {
            source = "hashicorp/local"
             version = "~> 2.0"
        }
    }
}

resource "local_file" "hello" {
 filename = "${path.module}/helloworld.txt"
 content = "Iac is love, helps a lot"
 file_permission = "0766"
 directory_permission = "0766"
} 

resource "local_sensitive_file" "hello_secret" {
    content = "This is a secret message that should not be exposed in logs or state files."
    filename = "${path.module}/secret_message.txt"
    file_permission = "0600"
    directory_permission = "0700"
} 