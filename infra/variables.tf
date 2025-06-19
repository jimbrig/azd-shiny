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

variable "app_secret_value" {
  description = "Secret value for the R Shiny application"
  type        = string
  default     = "default-secret-value"
  sensitive   = true
}

variable "min_replicas" {
  description = "Minimum number of container replicas"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum number of container replicas"
  type        = number
  default     = 3
}
