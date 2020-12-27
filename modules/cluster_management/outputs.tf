output nginx-lb-ip {
  value = data.kubernetes_service.nginx-lb[*].load_balancer_ingress[*].ip
  depends_on = [
    helm_release.nginx_controller[0]
  ]
}

output flux-deploy-key {
  value = file("${path.root}/flux-deploy-key.pub")

  depends_on = [
    helm_release.helm-operator[0]
  ]
}

