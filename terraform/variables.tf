variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-southeast-1"
}

variable "cluster_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "softbd-k8s"
}

variable "instance_type" {
  description = "EC2 instance type for all nodes"
  type        = string
  default     = "t3.small"
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI for ap-southeast-1"
  type        = string
  default     = "ami-0672fd5b9210aa093"
}

variable "public_key_path" {
  description = "Path to the SSH public key"
  type        = string
  default     = "C:/Users/hmsmi/.ssh/k8s-key.pub"
}