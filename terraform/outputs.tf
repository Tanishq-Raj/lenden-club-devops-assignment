output "instance_name" {
  description = "Name of the compute instance"
  value       = google_compute_instance.web_server.name
}

output "instance_public_ip" {
  description = "Public IP address of the compute instance"
  value       = google_compute_instance.web_server.network_interface[0].access_config[0].nat_ip
}

output "instance_private_ip" {
  description = "Private IP address of the compute instance"
  value       = google_compute_instance.web_server.network_interface[0].network_ip
}

output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.vpc_network.name
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${google_compute_instance.web_server.network_interface[0].access_config[0].nat_ip}:3000"
}
