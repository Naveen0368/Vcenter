provider "vsphere" {
  user                 = "devops@vsphere.local" # Replace with your vSphere username
  password             = "jC3`@JRrW9m"          # Replace with your vSphere password
  vsphere_server       = "10.128.7.21"          # Replace with your vSphere server IP
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
  name             = "vm-test-29-05"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  host_system_id   = data.vsphere_host.host.id

  num_cpus  = 4    # Change the number of CPUs to 4
  memory    = 8192 # Change memory to 8 GB (in megabytes)
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

