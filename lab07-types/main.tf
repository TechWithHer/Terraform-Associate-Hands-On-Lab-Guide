
output "first_zone" {
  value = var.zones[0]
}

output "team_tag" {
  value = var.tags["team"]
}

output "server_cpu" {
  value = var.server["name"]
}

output "tuple_num" {
  value = var.mixed[2]
}
