terraform {
	required_providers {
		local = {
			source = "hashicorp/local"  
			version = "~> 2.5"
}
		time = {
			source = "hashicorp/time"
			version = "~>0.11"
}
}
}

resource "time_static" "build_time" {
}

data "local_file" "template" {
	filename = "${path.module}/template.txt"
	}

resource "local_file" "rendered" {
	filename = "${path.module}/rendered.txt"
	content = "Build at ${time_static.build_time.rfc3339} \n Template in the file is: ${data.local_file.template.content}"
}
