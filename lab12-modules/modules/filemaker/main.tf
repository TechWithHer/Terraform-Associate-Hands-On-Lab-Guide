terraform {
	required_providers {
		local = {
			source = "hashicorp/local"
			version = "~>2.5"
}
}
}

resource "local_file" "this" {
	filename = "${path.root}/${var.name}.txt"
	content = var.content
}


