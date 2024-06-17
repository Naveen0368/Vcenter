variable "username" {
  description = "vSphere username"
  type        = string
}

variable "password" {
  description = "vSphere password"
  type        = string
  sensitive   = true
}

variable "vsphere_server" {
  description = "vSphere server IP"
  type        = string
}

variable "vm_name" {
  description = "Name for the virtual machine"
  type        = string
}

provider "vsphere" {
  user                 = var.username
  password             = var.password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "GLOBAL-SF10-LAB"
}

data "vsphere_compute_cluster" "cluster" {
  name          = "Linux Cluster" # Replace with your cluster name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = "esx11-DS3"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = "VM Network" # Replace with your network name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = "devopsubt24-template"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_host" "host" {
  name          = "ul-sf10-502-lab-esx11.unitedlayer.com" # Replace with your host name
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "vm" {
  name             = var.vm_name
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  host_system_id   = data.vsphere_host.host.id

  num_cpus  = 2
  memory    = 4096
  guest_id  = data.vsphere_virtual_machine.template.guest_id
  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = "vmxnet3"
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = false
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
}

data "vsphere_virtual_machine" "vm_info" {
  name          = vsphere_virtual_machine.vm.name
  datacenter_id = data.vsphere_datacenter.dc.id
  depends_on    = [vsphere_virtual_machine.vm]
}

output "vm_details" {
  value = {
    vm_name    = vsphere_virtual_machine.vm.name
    host_name  = data.vsphere_host.host.name
    ip_address = vsphere_virtual_machine.vm.default_ip_address
  }
}
