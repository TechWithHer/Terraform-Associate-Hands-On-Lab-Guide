terraform {
 	required_providers {
  		random = {
   			source = "hashicorp/random"
   			version = "~>3.6"
}  
}
}

 resource "local_file" "myfile" {
  	filename = "myfile.txt"
  	content = "This is a sample file"
}
 resource "random_pet" "servers" {
  	length = 2
  	separator = "-"
}


