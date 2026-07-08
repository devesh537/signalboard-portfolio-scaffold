variable "project_name" {
  type = string
}
variable "environment" {
  type = string
}
variable "cluster_version" {
  type    = string
  default = "1.32"
}
variable "vpc_id" {
  type = string
}
variable "subnet_ids" {
  type = list(string)
}
variable "node_pools" {
  type        = list(string)
  default     = ["general-purpose"]
  description = "EKS Auto Mode node pools. Add \"system\" for larger/prod clusters."
}
