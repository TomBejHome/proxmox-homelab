locals {
  control_plane_nodes = {
    for key, node in var.talos_nodes : key => node
    if node.role == "controlplane"
  }

  worker_nodes = {
    for key, node in var.talos_nodes : key => node
    if node.role == "worker"
  }

  control_plane_key = one(keys(local.control_plane_nodes))
  control_plane     = local.control_plane_nodes[local.control_plane_key]
  control_plane_ip  = split("/", local.control_plane.ipv4_address)[0]

  talos_node_ips = {
    for key, node in var.talos_nodes : key => split("/", node.ipv4_address)[0]
  }
}

provider "talos" {}

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

# --- CONTROL PLANE ---

data "talos_machine_configuration" "cp" {
  cluster_name     = var.talos_cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = "https://${local.control_plane_ip}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  config_patches = [
    yamlencode({
      machine = {
        install = { disk = local.control_plane.install_disk }
        network = {
          hostname = local.control_plane.name
          interfaces = [
            {
              interface = local.control_plane.network_device
              dhcp      = false
              addresses = [local.control_plane.ipv4_address]
              routes = [
                {
                  network = "0.0.0.0/0"
                  gateway = local.control_plane.gateway
                }
              ]
            }
          ]
        }
      }
    })
  ]
}

resource "talos_machine_configuration_apply" "cp" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.cp.machine_configuration
  node                        = local.control_plane_ip
  endpoint                    = local.control_plane_ip
  depends_on                  = [proxmox_virtual_environment_vm.talos]
}

# --- WORKER NODES ---

data "talos_machine_configuration" "worker" {
  for_each         = local.worker_nodes
  cluster_name     = var.talos_cluster_name
  machine_type     = "worker"
  cluster_endpoint = "https://${local.control_plane_ip}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  config_patches = [
    yamlencode({
      machine = {
        nodeLabels = { "node-role.kubernetes.io/worker" = "" }
        install = {
          disk = each.value.install_disk
          extensions = [
            {
              image = "ghcr.io/siderolabs/iscsi-tools:${var.talos_version}"
            }
          ]
        }
        network = {
          hostname = each.value.name
          interfaces = [
            {
              interface = each.value.network_device
              dhcp      = false
              addresses = [each.value.ipv4_address]
              routes = [
                {
                  network = "0.0.0.0/0"
                  gateway = each.value.gateway
                }
              ]
            }
          ]
        }
      }
    })
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  for_each = local.worker_nodes

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker[each.key].machine_configuration
  node                        = local.talos_node_ips[each.key]
  endpoint                    = local.talos_node_ips[each.key]
  depends_on                  = [proxmox_virtual_environment_vm.talos]
}

# --- CLUSTER BOOTSTRAP A CONFIGS ---

resource "talos_machine_bootstrap" "this" {
  depends_on           = [talos_machine_configuration_apply.cp]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.control_plane_ip
  endpoint             = local.control_plane_ip
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_machine_bootstrap.this]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.control_plane_ip
}

data "talos_client_configuration" "this" {
  cluster_name         = var.talos_cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = values(local.talos_node_ips)
  endpoints            = [local.control_plane_ip]
}

resource "local_file" "talosconfig" {
  content  = data.talos_client_configuration.this.talos_config
  filename = "${path.module}/talosconfig.yaml"
}

resource "local_file" "kubeconfig" {
  content  = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename = "${path.module}/kubeconfig.yaml"
}
