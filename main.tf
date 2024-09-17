terraform {
  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.13.7"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# Configure the Google Cloud and Tailscaleprovider
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "tailscale" {
  api_key = var.tailscale_api_key
  tailnet = var.tailscale_tailnet
}


# Create a Tailscale auth key with a tag, no clear if this override the tag on the device.
resource "tailscale_tailnet_key" "setup_key" {
  reusable      = true
  ephemeral     = false
  preauthorized = true
  expiry        = 3600 # 1 hour
  tags          = ["tag:router"]
}

# Create a VPC networks
resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
}


resource "google_compute_subnetwork" "subnet" {
  name          = "${var.network_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
}



# Create the Tailscale router VM
resource "google_compute_instance" "tailscale_router" {
  name         = "tailscale-router"
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.subnet.name

    access_config {
      // public IP
    }
  }

  metadata_startup_script = <<-EOF
              #!/bin/bash
              apt-get update && apt-get install -y curl
              curl -fsSL https://tailscale.com/install.sh | sh
              echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
              echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
              sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
              tailscale up --advertise-routes=${var.subnet_cidr} --authkey=${tailscale_tailnet_key.setup_key.key} --advertise-tags=tag:router
              EOF

  tags = ["tailscale-router"]
}

# Create the Tailscale device VM 
resource "google_compute_instance" "tailscale_device" {
  name         = "tailscale-device"
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.subnet.name

    access_config {
      // public IP
    }
  }

  metadata_startup_script = <<-EOF
              #!/bin/bash
              apt-get update && apt-get install -y curl
              curl -fsSL https://tailscale.com/install.sh | sh
              tailscale up --authkey=${tailscale_tailnet_key.setup_key.key}
              EOF

  tags = ["tailscale-device"]
}

# Firewall rule to allow Tailscale UDP traffic
resource "google_compute_firewall" "allow_tailscale" {
  name    = "allow-tailscale"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "udp"
    ports    = ["41641"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["tailscale-router", "tailscale-device"]
}

# Firewall rule to allow ICMP in the subnet (fake L2 cloud network)
resource "google_compute_firewall" "allow_internal_icmp" {
  name    = "allow-internal-icmp"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr]
}
# Firewall rule to allow ssh in the subnet
resource "google_compute_firewall" "allow_internal_ssh" {
  name    = "allow-internal-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.subnet_cidr]
}

