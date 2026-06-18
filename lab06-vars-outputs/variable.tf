variable "environment" {
	type = string 
	description = "Deployment Environment"
	default = "dev"
}

variable "instance_count" {
	type = number
	default = 2
}

variable "enable_logging" {
	type = bool
	default = true
}

variable "db_password" {
	type = string
	sensitive = true
	default = "changemeeee!"
}

