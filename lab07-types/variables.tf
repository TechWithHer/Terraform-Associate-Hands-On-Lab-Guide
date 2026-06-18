variable "tags" {
  type = map(string)
  default = {
    team = "platform"
    tier = "backend"
  }
}
variable "zones" {
  type    = list(string)
  default = ["a", "b", "c"]

}
variable "ports" {
  type    = set(number)
  default = [80, 443, 8080]
}
variable "server" {
  type = object({
    name    = string
    cpu     = number
    enabled = bool
  })
  default = {
    name    = "web"
    cpu     = 2
    enabled = true
  }
}

variable "mixed" {                      # tuple (ordered, mixed types, fixed length)
  type    = tuple([string, number, bool])
  default = ["x", 1, true]
}