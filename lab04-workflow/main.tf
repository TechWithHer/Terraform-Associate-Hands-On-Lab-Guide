terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
resource "random_string" "suffix" {
	count = 4
	length = 6
	numeric = false
	special = false
        upper = false
}
resource "local_file" "report" {
  count = 4
  filename = "${path.module}/report-${random_string.suffix[count.index].id}.txt"
  content  = "Created a file name with custom name"
  
}


