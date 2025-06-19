variable "location" {
  description = "Azure region for deployment"
  type        = string
}

variable "environment_name" {
  description = "Name of the azd environment"
  type        = string
}

variable "image_name" {
  description = "Container image name"
  type        = string
  default     = "shinyapp"
}
