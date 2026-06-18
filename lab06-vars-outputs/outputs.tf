output "config_path" {
	value = local_file.config.filename
	description = " Path to the generated config"

}

output "passwords" {
	value = var.db_password
	sensitive = true
}

