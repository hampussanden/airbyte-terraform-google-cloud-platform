variable "region" {
  default     = "europe-west1"
  description = "Google Cloud Platform Region"
  type        = string
}

variable "zone" {
  default     = "europe-west1-b"
  description = "Google Cloud Platform Zone"
  type        = string
}

variable "machine_type" {
  default = "e2-medium"
  description = "Google Cloud Platform Machine Type"
  type = string
}

variable "project_id" {
  default     = "tcb-project-371706-400508"
  description = "Google Cloud Platform Project ID"
  type        = string
}

variable "project_name" {
  default     = "tcb-project-371706"
  description = "Google Cloud Platform Project Name"
  type        = string
}

variable "billing_account" {
  description = "Google Cloud Platform Billing Account ID"
  type        = string
}