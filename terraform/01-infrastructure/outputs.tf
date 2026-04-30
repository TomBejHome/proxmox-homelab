output "talos_cp_ip" {
  description = "IP adresa Control Plane"
  value       = local.control_plane_ip
}

output "talos_node_ips" {
  description = "IP adresy všech Talos nodů"
  value       = local.talos_node_ips
}

# Výstup pro ovládání Talos OS (talosctl)
output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}
