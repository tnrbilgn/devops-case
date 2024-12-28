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
  
  
  provisioner "install" {
    source      = "~/devops-case/scripts/setup/install.sh"   
    destination = "/tmp/install.sh" 
  }
  
  provisioner "kind-config" {
    source      = "./kind-config.yaml"   
    destination = "/tmp/kind-config.yaml" 
  }
  
  provisioner "update_jenkins" {
    source      = "~/devops-case/scripts/setup/update-jenkins.sh"   
    destination = "/tmp/update-jenkins.sh" 
  }
  
  provisioner "helm-k8s-local" {
    source      = "~/devops-case/scripts/setup/helm-k8s-local.sh"   
    destination = "/tmp/helm-k8s-local.sh" 
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
  ssh-keys = "tanerbilgin94:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDA8Wdl/sLsTjDIpcAi5sV0PE7FlkEF9v7q4lekOBZSpITG4bied5AACm1YZcNxakKjWUCH/kAtJOE4YNOGAPqfaiapGSjf8f0UXk1vOTshkw5R+N23poeww/tBAcWEH2PeK4DAUQAAq03SNDF2+HwLEDYBDkzSPs3htu5+CnK6g4I7iTqhcbEnc4p0Lm7Vtx0VKZ7YVTo7amPe2Nga7T/+YLvPDsTBE5jqlgzzDaJkrZD7CTC3FhqA+03ZqoHIxFz5v5VJgSFZKsl1B5cN+09STDHNQxBtsW6nKCggowirfDCOTy0ks1sa9GqR0GOR/0+Ixq+a5KAcPds/5ci0dpXhYbRD4EyPstJSwG1C9NRftGrtIbtRFW3KU4UWozEzo1vGYo8zqpDL4GQdrl/+diZz1A3AO3rsHUIJWBC0WlhFVv6Wm84rj6/kX7/cutCbwBJDawXQE+QrzdSSB84SPe3rkoczejYbFgX9A0pG1iTiI+xGH0UAibnpTFOxhV8d9OU= tanerbilgin94"
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

resource "null_resource" "update_jenkins" {
  depends_on = [google_compute_instance.vm_instance]
  connection {
    type     = "ssh"
    user     = var.user_name
    host     = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
    private_key = file("~/.ssh/devops-test")
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Running update jenkins script...' > /tmp/update_jenkins.txt",
      "sh /tmp/update_jenkins.sh >> /tmp/update_jenkins.txt 2>&1"
    ]
  }
}

resource "null_resource" "helm-k8s-local" {
  depends_on = [google_compute_instance.vm_instance]
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
