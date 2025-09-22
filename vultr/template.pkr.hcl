variable "vultr_api_key" {
  type      = string
  default   = "${env("VULTR_API_KEY")}"
  sensitive = true
}

variable "image_name" {
  type      = string
  default   = "immich-24-04-snapshot-{{timestamp}}"
}

variable "apt_packages" {
  type      = string
  default   = "apt-transport-https ca-certificates curl jq linux-image-extra-virtual software-properties-common "
}

variable "application_name" {
  type      = string
  default   = "Immich"
}

variable "application_version" {
  type      = string
  default   = "release"
}

variable "docker_compose_version" {
  type      = string
  default   = ""
}

variable "ci_branch_name" {
  type      = string
  default   = "${env("GITHUB_IMMICH_BRANCH")}"
}

variable "immich_test_run_timeout" {
  type      = string
  default   = "${env("IMMICH_TEST_RUN_TIMEOUT")}"
}

variable "immich_test_run_endpoint" {
  type      = string
  default   = "${env("IMMICH_TEST_RUN_ENDPOINT")}"
}

variable "immich_test_run_sleep_time" {
  type      = string
  default   = "${env("IMMICH_TEST_RUN_SLEEP_TIME")}"
}

variable "immich_test_prod_branch" {
  type      = string
  default   = "${env("IMMICH_TEST_PROD_BRANCH")}"
}

packer {
    required_plugins {
        vultr = {
            version = ">=v2.3.2"
            source = "github.com/vultr/vultr"
        }
    }
}

source "vultr" "immich-snapshot" {
  api_key              = "${var.vultr_api_key}"
  os_id                = "2284"
  plan_id              = "marketplace-2c-2gb"
  region_id            = "dfw"
  snapshot_description = "Immich Snapshot ${formatdate("YYYY-MM-DD hh:mm", timestamp())}"
  ssh_username         = "root"
  state_timeout        = "60m"
}

build {
  sources = ["source.vultr.immich-snapshot"]

  provisioner "file" {
    source = "./vultr-helper.sh"
    destination = "/root/vultr-helper.sh"
  }

  provisioner "file" {
    source = "files/var/"
    destination = "/var/"
  }

  provisioner "file" {
    source = "files/etc/"
    destination = "/etc/"
  }

  provisioner "file" {
    source = "../generic/files/opt/"
    destination = "/opt/"
  }



  provisioner "shell" {
    script = "install-immich-start.sh"
    remote_folder = "/root"
    remote_file = "install-immich-start.sh"
  }

  provisioner "shell" {
    script = "install-immich-stop.sh"
    remote_folder = "/root"
    remote_file = "install-immich-stop.sh"
  }

  provisioner "shell" {
    script = "../generic/scripts/010-docker.sh"
    remote_folder = "/root"
    remote_file = "010-docker.sh"
  }

  provisioner "shell" {
    script = "../generic/scripts/011-docker-compose.sh"
    remote_folder = "/root"
    remote_file = "011-docker-compose.sh"
  }

  provisioner "shell" {
    script = "../generic/scripts/012-grub-opts.sh"
    remote_folder = "/root"
    remote_file = "012-grub-opts.sh"
  }

  provisioner "shell" {
    script = "../generic/scripts/013-docker-dns.sh"
    remote_folder = "/root"
    remote_file = "013-docker-dns.sh"
  }

  provisioner "shell" {
    script = "../generic/scripts/015-immich.sh"
    remote_folder = "/root"
    remote_file = "015-immich.sh"
  }

  provisioner "shell" {
    script = "../generic/scripts/016-ufw-immich.sh"
    remote_folder = "/root"
    remote_file = "016-ufw-immich.sh"
  }
  provisioner "shell" {
    script = "../generic/scripts/020-application-tag.sh"
    remote_folder = "/root"
    remote_file = "020-application-tag.sh"
  }

  provisioner "shell" {
    script = "../generic/scripts/90-cleanup.sh"
    remote_folder = "/root"
    remote_file = "90-cleanup.sh"
  }
  provisioner "shell" {
    script = "scripts/95-pre-check.sh"
    remote_folder = "/root"
    remote_file = "95-pre-check.sh"
  }

  provisioner "shell" {
    inline = [
      "sudo bash -c '/root/install-immich.sh stop'",
      "sudo rm -f /root/install-immich.sh"
    ]
  }
}