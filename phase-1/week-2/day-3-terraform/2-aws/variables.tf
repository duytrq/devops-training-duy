variable "aws_region" {
  description = "AWS region to provision resources in."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Name prefix for resources."
  type        = string
  default     = "devops-training"
}

variable "project_owner" {
  description = "Owner of the resources"
  type        = string
  default     = "duy"
}

variable "ssh_allowed_cidr" {
  description = "Your public IP in CIDR format for SSH access, for example 203.0.113.10/32."
  type        = string
}

variable "key_name" {
  description = "Optional existing EC2 key pair name for SSH login."
  type        = string
  default     = null
}
