#########################################
# 📦 Variables
#########################################

variable "prefix" {
  description = "Name prefix for all resources"
  type        = string
  default     = "p2"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "Sweden Central"
}
