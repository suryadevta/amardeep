variable "key_name" {
  description = "The name for ssh key, used for aws_launch_configuration"
  type        = string
  default     = "Jenkins"
}

variable "cluster_name" {
  description = "The name of AWS ECS cluster"
  type        = string
  default     = "gravystack-Prod"
}