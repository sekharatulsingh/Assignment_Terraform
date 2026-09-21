variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "ecs_security_group_id" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "allocated_storage" {
  type = number
}

variable "max_allocated_storage" {
  type = number
}

variable "database_name" {
  type      = string
  sensitive = false
}

variable "database_username" {
  type      = string
  sensitive = false
}

variable "database_password" {
  type      = string
  sensitive = true
}

variable "backup_retention_days" {
  type = number
}

variable "deletion_protection" {
  type = bool
}

variable "multi_az" {
  type = bool
}

variable "skip_final_snapshot" {
  type = bool
}
