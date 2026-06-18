locals {
	names = ["Sonal", "Meenal", "Arpit"]
	upper = [for n in local.names : upper(n)]
	lengths = { for n in local.names: n => length(n) }
	is_prod = terraform.workspace == "prod"
	size = local.is_prod ? "large":"small"
	joined = join(",", local.names)
	first_two = slice(local.names, 0,2)
	merged = merge({a = 1},{b = 2})
	has_nal= contains(local.names ,"nal")
}

output "upper" {value = local.upper}
output "lengths" { value = local.lengths }
output "size" { value = local.size }
output "first_two" {value =  local.first_two}
output "merged" {value = local.merged }
output "has_nal" {value = local.has_nal}
output "current_workspace" {
  value = terraform.workspace
}
