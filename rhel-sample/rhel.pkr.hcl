packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "tenant_id" {
  default = env("ARM_TENANT_ID")
}

variable "subscription_id" {
  default = env("ARM_SUBSCRIPTION_ID")
}

variable "client_id" {
  default = env("ARM_CLIENT_ID")
}

variable "client_secret" {
  default = env("ARM_CLIENT_SECRET")
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "rhel" {
  ami_name      = "learn-packer-linux-aws-${local.timestamp}"
  instance_type = "t2.micro"
  region        = "us-west-2"
  source_ami_filter {
    filters = {
      name                = "*RHEL-8.3.0_HVM-20201031-x86_64-0-Hourly2-GP2*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["309956199498"]
  }
  ssh_username = "ec2-user"
}

source "azure-arm" "rhel" {
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id

  managed_image_name                = "learn-packer-linux-azure-${local.timestamp}"
  managed_image_resource_group_name = "myResourceGroup"

  os_type         = "Linux"
  image_publisher = "RedHat"
  image_offer     = "RHEL"
  image_sku       = "8.2"
  image_version   = "latest"


  azure_tags = {
    dept = "engineering"
  }

  location = "East US"
  vm_size  = "Standard_DS2_v2"
}


build {
  sources = [
    "source.amazon-ebs.rhel",
    "source.azure-arm.rhel"
  ]

  provisioner "shell" {
    environment_vars = [
      "FOO=hello world",
    ]
    inline = [
      "echo Installing nginx",
      "sleep 5",
      "sudo yum update -y",
      "sudo yum install -y nginx",
      "echo \"FOO is $FOO\" > example.txt",
    ]
  }
}

