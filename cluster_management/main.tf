resource helm_release nginx-controller {
  count            = var.nginx_controller == true ? 1 : 0
  name             = "ingress-nginx"
  namespace        = "nginx"
  create_namespace = true
  chart            = "${path.module}/new/ingress-nginx"

  values = [
    file("${path.module}/new/ingress-nginx/values.yaml")
  ]
}

data kubernetes_service nginx-lb {
  count = var.nginx_controller == true ? 1 : 0
  metadata {
    #name      = "${helm_release.nginx-controller[count.index].name}-controller"
    #namespace = helm_release.nginx-controller[count.index].namespace
    name      = "${join("", helm_release.nginx-controller[*].name)}-controller"
    namespace = join("", helm_release.nginx-controller[*].namespace)
  }
  depends_on = [
    helm_release.nginx-controller
  ]
}

output nginx-lb-ip {
  value = data.kubernetes_service.nginx-lb[*].load_balancer_ingress[*].ip
  #value = "${join("", helm_release.nginx-controller[*].name)}-controller"
  depends_on = [
    helm_release.nginx_controller[0]
  ]
}

resource helm_release flux {
  count            = var.flux == true ? 1 : 0
  name             = "flux"
  namespace        = "flux"
  create_namespace = true
  chart            = "${path.module}/new/flux"
  wait             = true

  values = [
    file("${path.module}/new/flux/values.yaml")
  ]

  set {
    name  = "git.url"
    value = var.config_repo
  }

  provisioner local-exec {
    command = "kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/crds.yaml"
  }
}

resource helm_release helm-operator {
  count            = var.flux == true ? 1 : 0
  name             = "helm-operator"
  namespace        = "flux"
  create_namespace = true
  chart            = "${path.module}/new/helm-operator"
  wait             = true

  depends_on = [
    helm_release.flux[0]
  ]

  values = [
    file("${path.module}/new/helm-operator/values.yaml")
  ]

  set {
    name  = "git.ssh.secretName"
    value = "flux-git-deploy"
  }

  set {
    name  = "helm.versions"
    value = "v3"
  }

  provisioner local-exec {
    command = "fluxctl identity --k8s-fwd-ns flux > ${path.root}/flux-deploy-key.pub"
  }
}

output flux-deploy-key {
  value = file("${path.root}/flux-deploy-key.pub")

  depends_on = [
    helm_release.helm-operator[0]
  ]
}

resource helm_release logger {
  name  = "logger"
  chart = "${path.module}/new/kube-logging"
}