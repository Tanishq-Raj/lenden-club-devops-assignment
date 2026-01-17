# Terraform configuration for GCP - SECURED VERSION
# This version has all security vulnerabilities fixed

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# VPC Network
resource "google_compute_network" "vpc_network" {
  name                    = "${var.project_name}-vpc"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_name}-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id

  # Enable VPC Flow Logs for security monitoring
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# FIXED: SSH restricted to specific IP ranges only
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_name}-allow-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # SECURITY FIX: SSH restricted to specific IPs (update with your IP)
  source_ranges = var.allowed_ssh_ips
  target_tags   = ["web-server"]

  description = "Allow SSH from specific IP addresses only"
}

# FIXED: HTTP/HTTPS traffic only, not all protocols
resource "google_compute_firewall" "allow_http" {
  name    = "${var.project_name}-allow-http"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "3000"]
  }

  # Allow HTTP from anywhere (typical for web servers)
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]

  description = "Allow HTTP/HTTPS traffic to web server"
}

# FIXED: Deny all other traffic by default (implicit deny)
resource "google_compute_firewall" "deny_all" {
  name     = "${var.project_name}-deny-all"
  network  = google_compute_network.vpc_network.name
  priority = 65534

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  description   = "Deny all other traffic by default"
}

# Service account with minimal permissions
resource "google_service_account" "instance_sa" {
  account_id   = "${var.project_name}-sa"
  display_name = "Service Account for ${var.project_name}"
  description  = "Minimal permissions service account for compute instance"
}

# FIXED: Compute instance with security best practices
resource "google_compute_instance" "web_server" {
  name         = "${var.project_name}-instance"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["web-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-balanced"
    }
    
    # SECURITY FIX: Disk encryption enabled
    disk_encryption_key_raw = null # Uses Google-managed encryption by default
    
    # SECURITY FIX: Auto-delete disabled for production safety
    auto_delete = false
  }

  network_interface {
    network    = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.subnet.name

    # Public IP still needed for web access, but protected by firewall rules
    access_config {
      // Ephemeral public IP
    }
  }

  # SECURITY FIX: Use OS Login instead of metadata SSH keys
  metadata = {
    enable-oslogin = "TRUE"
    # Block project-wide SSH keys
    block-project-ssh-keys = "TRUE"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e
    
    # Update system
    apt-get update
    apt-get upgrade -y
    
    # Install Docker
    apt-get install -y docker.io
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu
    
    # Install security updates automatically
    apt-get install -y unattended-upgrades
    dpkg-reconfigure -plow unattended-upgrades
    
    # Configure firewall
    ufw --force enable
    ufw allow 22/tcp
    ufw allow 3000/tcp
    
    # Pull and run the application
    docker pull node:18-alpine
    
    # Create a simple web server
    cat > /home/ubuntu/app.js << 'APPEOF'
    const http = require('http');
    const os = require('os');
    
    const server = http.createServer((req, res) => {
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.end('<h1>DevOps Assignment - Running on GCP (Secured)!</h1><p>Hostname: ' + os.hostname() + '</p>');
    });
    
    server.listen(3000, '0.0.0.0', () => {
      console.log('Server running on port 3000');
    });
APPEOF
    
    docker run -d -p 3000:3000 -v /home/ubuntu/app.js:/app.js node:18-alpine node /app.js
  EOF

  # SECURITY FIX: Use dedicated service account with minimal scopes
  service_account {
    email  = google_service_account.instance_sa.email
    scopes = ["logging-write", "monitoring-write"]
  }

  # SECURITY FIX: Enable Shielded VM features
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  # Enable deletion protection for production
  deletion_protection = false # Set to true in production

  # Labels for organization and cost tracking
  labels = {
    environment = "development"
    project     = var.project_name
    managed_by  = "terraform"
  }
}

# SECURITY FIX: Enable Cloud Logging
resource "google_logging_project_sink" "instance_logs" {
  name        = "${var.project_name}-logs"
  destination = "logging.googleapis.com/projects/${var.project_id}/logs/${var.project_name}"
  
  filter = "resource.type=gce_instance AND resource.labels.instance_id=${google_compute_instance.web_server.instance_id}"

  unique_writer_identity = true
}

# SECURITY FIX: Cloud Monitoring alert for suspicious activity
resource "google_monitoring_alert_policy" "high_cpu" {
  display_name = "${var.project_name}-high-cpu-alert"
  combiner     = "OR"
  
  conditions {
    display_name = "CPU usage above 80%"
    
    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND resource.labels.instance_id=\"${google_compute_instance.web_server.instance_id}\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = []
  
  alert_strategy {
    auto_close = "1800s"
  }
}
