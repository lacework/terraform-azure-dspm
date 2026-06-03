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

variable "integration_level" {
  description = "Whether the deployment service principal will deploy a 'SUBSCRIPTION' or 'TENANT' level integration. TENANT additionally grants the SP rights to manage role definitions and assignments at the tenant root management group, which the root module requires to grant the scanner read access across all subscriptions."
  type        = string
  default     = "SUBSCRIPTION"
  validation {
    condition     = upper(var.integration_level) == "SUBSCRIPTION" || upper(var.integration_level) == "TENANT"
    error_message = "Valid values are 'SUBSCRIPTION' or 'TENANT'."
  }
}
