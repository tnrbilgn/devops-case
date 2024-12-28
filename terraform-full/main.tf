provider "google" {
  credentials = file("devops-test.json")
  project = "devops-test-445411"
  region  = "us-central1"
}


resource "google_compute_instance" "vm_instance" {
  name         = "terraform-vm"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size = 50
    }
  }

  network_interface {
    network = "default"
    subnetwork = "default"
    access_config {
	}
  }
  
  tags = [
  "http-server",
  "ssh-server"
  ]
  
  
  provisioner "file" {
    source      = "~/devops-case/scripts/setup/install"   
    destination = "/tmp/install.sh" 
  }
  
  provisioner "file" {
    source      = "./kind-config.yaml"   
    destination = "/tmp/kind-config.yaml" 
  }
  
  provisioner "file" {
    source      = "~/devops-case/scripts/setup/helm-k8s-local"   
    destination = "/tmp/helm-k8s-local.sh" 
  }
  
  provisioner "file" {
    source      = "~/devops-case/kubernetes"   
    destination = "/tmp/kubernetes" 
  }
  
  provisioner "file" {
    source      = "~/devops-case/helm-charts"   
    destination = "/tmp/helm-charts" 
  }
  
  provisioner "remote-exec" {
    inline = [
      "echo 'Running installation script...' > /tmp/install_log.txt",
      "sh /tmp/install.sh >> /tmp/install_log.txt 2>&1"
    ]
    }
    
    connection {
      type        = "ssh"
      user        = var.user_name
      private_key = file("~/.ssh/devops-test")
      host        = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
    }
 
  metadata = {
  ssh-keys = "tanerbilgin94:${file("./devops-test.pub")}"
  }
}



resource "google_compute_firewall" "allow_tcp" {
  name    = "allow-tcp"
  #network = google_compute_network.default.self_link
  network = "default"

 allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server", "ssh-server"]
}

resource "null_resource" "kind_cluster" {
  depends_on = [google_compute_instance.vm_instance]
  connection {
    type     = "ssh"
    user     = var.user_name
    host     = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
    private_key = file("~/.ssh/devops-test")
  }

  provisioner "remote-exec" {
    inline = [
      "kind create cluster --name devops-cluster --config /tmp/kind-config.yaml"
    ]
  }
}

resource "null_resource" "helm-k8s-local" {
  depends_on = [null_resource.kind_cluster]
  connection {
    type     = "ssh"
    user     = var.user_name
    host     = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
    private_key = file("~/.ssh/devops-test")
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Running Helm install for postgres and redis...'",
      "sh /tmp/helm-k8s-local.sh >> /tmp/helm-k8s-local.txt 2>&1"
    ]
  }
}

resource "local_file" "vm_ip_output" {
  filename = "${path.module}/vm_ip.txt"
  content  = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}
