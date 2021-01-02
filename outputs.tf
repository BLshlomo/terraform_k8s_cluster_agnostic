output nginx-lb-ip {
  value = module.cluster_management.nginx-lb-ip
}

output flux-deploy-key {
  value = module.cluster_management.flux-deploy-key
}

output grafana-password {
  value = module.cluster_management.grafana-password
}
