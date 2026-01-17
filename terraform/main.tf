# Terraform configuration for GCP - INTENTIONALLY VULNERABLE VERSION
# This version contains security flaws that will be detected by Trivy

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
}

# VULNERABILITY 1: Firewall rule allowing SSH from anywhere (0.0.0.0/0)
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_name}-allow-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # SECURITY ISSUE: SSH open to the entire internet
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

# VULNERABILITY 2: Firewall rule allowing all traffic from anywhere
resource "google_compute_firewall" "allow_all" {
  name    = "${var.project_name}-allow-all"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "all"
  }

  # SECURITY ISSUE: All ports open to the internet
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

# VULNERABILITY 3: Compute instance without encryption and public IP
resource "google_compute_instance" "web_server" {
  name         = "${var.project_name}-instance"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["web-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard"
      # SECURITY ISSUE: Disk encryption not explicitly enabled
    }
    # SECURITY ISSUE: auto_delete should be false for production
    auto_delete = true
  }

  network_interface {
    network    = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.subnet.name

    # SECURITY ISSUE: Public IP exposed directly
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    # SECURITY ISSUE: SSH keys in metadata without proper management
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu
    
    # Pull and run the application
    docker pull node:18-alpine
    
    # Create a simple web server
    cat > /home/ubuntu/app.js << 'APPEOF'
    const http = require('http');
    const os = require('os');
    
    const server = http.createServer((req, res) => {
      res.writeHead(200, {'Content-Type': 'text/html'});
      res.end('<h1>DevOps Assignment - Running on GCP!</h1><p>Hostname: ' + os.hostname() + '</p>');
    });
    
    server.listen(3000, '0.0.0.0', () => {
      console.log('Server running on port 3000');
    });
APPEOF
    
    docker run -d -p 3000:3000 -v /home/ubuntu/app.js:/app.js node:18-alpine node /app.js
  EOF

  # SECURITY ISSUE: No service account with minimal permissions
  service_account {
    # Using default service account with broad permissions
    scopes = ["cloud-platform"]
  }

  # SECURITY ISSUE: Shielded VM features not enabled
  # shielded_instance_config {
  #   enable_secure_boot          = true
  #   enable_vtpm                 = true
  #   enable_integrity_monitoring = true
  # }
}

# SECURITY ISSUE: No logging or monitoring configured
# SECURITY ISSUE: No backup policy
# SECURITY ISSUE: No IAM policies restricting access
