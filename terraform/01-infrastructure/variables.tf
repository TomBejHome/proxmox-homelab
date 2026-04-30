variable "proxmox_endpoint" {
  type        = string
  description = "Proxmox API endpoint."
}

variable "proxmox_api_token_id" {
  type        = string
  description = "Proxmox API token ID in the form user@realm!token-name."
  sensitive   = true

  validation {
    condition     = !strcontains(var.proxmox_api_token_id, "=")
    error_message = "Use only the token ID here, for example terraform-prov@pve!tf-token. Put the secret in proxmox_api_token_secret."
  }
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "Proxmox API token secret."
  sensitive   = true
}

variable "proxmox_insecure" {
  type        = bool
  description = "Disable TLS certificate verification for the Proxmox API."
  default     = false
}

variable "proxmox_node_name" {
  type        = string
  description = "Proxmox node where Talos VMs will run."
}

variable "proxmox_datastore_id" {
  type        = string
  description = "Proxmox datastore for VM disks and initialization data."
}

variable "proxmox_network_bridge" {
  type        = string
  description = "Proxmox network bridge for Talos VMs."
}

variable "talos_iso_file_id" {
  type        = string
  description = "Proxmox file ID of the Talos ISO."
}

variable "talos_cluster_name" {
  type        = string
  description = "Talos/Kubernetes cluster name."
}

variable "talos_version" {
  type        = string
  description = "Talos version used for generated machine secrets and extensions."
}

variable "talos_nodes" {
  type = map(object({
    name             = string
    role             = string
    vm_id            = number
    cpu_cores        = number
    memory_dedicated = number
    disk_size        = number
    ipv4_address     = string
    gateway          = string
    network_device   = optional(string, "eth0")
    install_disk     = optional(string, "/dev/vda")
  }))
  description = "Talos node topology. IP addresses are defined here and reused by Proxmox and Talos configuration."

  validation {
    condition     = alltrue([for node in var.talos_nodes : contains(["controlplane", "worker"], node.role)])
    error_message = "Each Talos node role must be either controlplane or worker."
  }

  validation {
    condition     = length([for key, node in var.talos_nodes : key if node.role == "controlplane"]) == 1
    error_message = "Exactly one Talos node must have role controlplane."
  }

  validation {
    condition     = alltrue([for node in var.talos_nodes : can(cidrhost(node.ipv4_address, 0))])
    error_message = "Each Talos node ipv4_address must be a valid CIDR address, for example 192.168.10.100/24."
  }
}
