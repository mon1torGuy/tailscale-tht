# # variables.tf

variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
  default     = "# Replace with your project ID"
}

variable "tailscale_tailnet" {
  description = "Tailscale Tailnet name"
  type        = string
  default     = "# Replace with your Tailscale Tailnet name"
}

variable "tailscale_api_key" {
  description = "Tailscale API Key"
  type        = string
  sensitive   = true
  default     = "# Replace with your Tailscale API Key"
}


variable "region" {
  description = "The region to deploy resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The zone to deploy resources"
  type        = string
  default     = "us-central1-a"
}

variable "network_name" {
  description = "The name of the VPC network"
  type        = string
  default     = "tailscale-network"
}

variable "subnet_cidr" {
  description = "The CIDR range for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "machine_type" {
  description = "The machine type for the VMs"
  type        = string
  default     = "e2-micro"
}


