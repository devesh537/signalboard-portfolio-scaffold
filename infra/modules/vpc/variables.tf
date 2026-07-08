variable "project_name" {
  type = string
}
variable "environment" {
  type = string
}
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "az_count" {
  type    = number
  default = 3
}
variable "single_nat_gateway" {
  type        = bool
  default     = true
  description = "true = cost-optimized (dev/staging), false = one NAT per AZ (prod HA)"
}
