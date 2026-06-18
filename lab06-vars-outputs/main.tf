terraform {
	required_providers {
		local = {
			source = "hashicorp/local"
			version = "~>2.5"
}
}
}
resource "local_file" "config" {
	filename = "${path.module}/${var.environment}.conf" 
	content = "count=${var.instance_count}\nlogging=${var.enable_logging}\n"
} 


