packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "custom_ami_name" {
  type    = string
  default = "fedora-bastion"
}

variable "instance_type" {
  type    = string
  default = "t3a.medium"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "tag_owner" {
  type    = string
  default = "alex.ryndin"
}

source "amazon-ebs" "bastion" {
  ami_name      = "${var.custom_ami_name}"
  instance_type = "${var.instance_type}"
  region        = "${var.region}"
  source_ami_filter {
    filters = {
      name                = "Fedora-Cloud-Base-34-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
      architecture        = "x86_64"
    }
    most_recent = true
    owners      = ["aws-marketplace"]
  }
  ssh_username = "fedora"

  # https://github.com/hashicorp/packer/issues/10074#issuecomment-886137013
  user_data = <<-EOT
  #!/usr/bin/env bash
  update-crypto-policies --set LEGACY
  EOT

  tags = {
    owner         = "${var.tag_owner}"
    os            = "Linux"
    os_variant    = "Fedora"
    base_ami_id   = "{{ .SourceAMI }}"
    base_ami_name = "{{ .SourceAMIName }}"
  }
}

build {
  sources = ["source.amazon-ebs.bastion"]

  # first install ansible
  provisioner "shell" {
    inline = [
      "sudo dnf upgrade --refresh --assumeyes",
      "sudo dnf install --assumeyes python3 ansible"
    ]
  }

  # then use it to install everything else
  provisioner "ansible-local" {
    playbook_file   = "./playbook.yml"
    extra_arguments = ["-e", "ansible_python_interpreter=/usr/bin/python3"]
  }

  # as the last step turn security back on
  # https://github.com/hashicorp/packer/issues/10074#issuecomment-886137013
  provisioner "shell" {
    inline = ["sudo update-crypto-policies --set DEFAULT"]
  }
}
