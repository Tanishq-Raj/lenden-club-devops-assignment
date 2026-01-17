variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "your-gcp-project-id"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "devops-assignment"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "GCP machine type (e2-micro is free tier eligible)"
  type        = string
  default     = "e2-micro"
}

variable "allowed_ssh_ips" {
  description = "List of IP addresses allowed to SSH (CIDR notation)"
  type        = list(string)
  # IMPORTANT: Update this with your actual IP address
  # You can find your IP at https://whatismyipaddress.com/
  default     = ["YOUR_IP_ADDRESS/32"]
}
