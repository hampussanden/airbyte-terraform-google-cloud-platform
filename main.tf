# Enable APIs
resource "google_project_service" "api_services" {
  project = var.project_id
  for_each = toset(
    [
      "compute.googleapis.com",
      "cloudresourcemanager.googleapis.com",
    ]
  )
  service                    = each.key
  disable_on_destroy         = false
  disable_dependent_services = true
}

# Set IAM permissions for the service account
resource "google_project_iam_member" "project" {
  for_each = toset([
    "roles/iam.serviceAccountUser",
    "roles/run.admin",
    "roles/logging.admin",
    "roles/bigquery.jobUser",
    "roles/bigquery.dataEditor",
    "roles/iap.tunnelResourceAccessor"
  ])
  role       = each.value
  project    = var.project_id
  member     = "serviceAccount:${var.project_name}@${var.project_id}.iam.gserviceaccount.com"
  depends_on = [google_project_service.api_services]
}

# Create a VPC
resource "google_compute_network" "vpc" {
  name                    = "airbyte-network"
  auto_create_subnetworks = "false"

}

# Create a Subnet
resource "google_compute_subnetwork" "subnet" {
  name                     = "airbyte-subnet"
  ip_cidr_range            = "10.10.0.0/24"
  network                  = google_compute_network.vpc.name
  region                   = var.region
  private_ip_google_access = true # Allow access to internal Google services
}

## Create a VM in the above subnet

resource "google_compute_instance" "airbyte-instance" {
  project                 = var.project_id
  zone                    = var.zone
  name                    = "airbyte-instance"
  machine_type            = var.machine_type
  metadata_startup_script = file("./bin/airbyte.sh")

  boot_disk {
    initialize_params {
      image = "debian-10-buster-v20230912"
    }
  }

  network_interface {
    network    = "airbyte-network"
    subnetwork = google_compute_subnetwork.subnet.name # Replace with a reference or self link to your subnet, in quotes
  }

  # Enable Shielded VM features
  shielded_instance_config {
    enable_secure_boot = true
    enable_vtpm        = true
  }

  service_account {
    scopes = [
      "cloud-platform",
    ]
    email = "${var.project_name}@${var.project_id}.iam.gserviceaccount.com"
  }
}

# Create a firewall to allow SSH connection from the specified source range
resource "google_compute_firewall" "rules" {
  project = var.project_id
  name    = "allow-ssh"
  network = "airbyte-network"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
  depends_on    = [google_compute_network.vpc]
}

## Create Cloud Router

resource "google_compute_router" "router" {
  project    = var.project_id
  name       = "airbyte-router"
  network    = "airbyte-network"
  region     = var.region
  depends_on = [google_compute_network.vpc]
}

## Create Nat Gateway

resource "google_compute_router_nat" "nat" {
  name                               = "airbyte-router-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}