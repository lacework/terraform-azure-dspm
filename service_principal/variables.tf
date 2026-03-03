variable "service_principal_name" {
  description = "The display name for the Azure AD application and service principal."
  type        = string
  default     = "forticnapp-dspm-deployment-sp"
}

variable "scanning_subscription_id" {
  description = "The subscription ID where DSPM scanning resources will be deployed."
  type        = string
}

variable "client_secret_expiry_duration_hours" {
  description = "Duration in hours for the client secret's validity (e.g. '2160h' for 90 days)."
  type        = string
  default     = "4380h" # ~6 months
}
