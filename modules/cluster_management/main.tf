resource helm_release logger {
  count = var.logger == true ? 1 : 0
  name  = "logger"
  chart = "${path.module}/charts/kube-logging"
}

resource helm_release prometheus {
  count            = var.prometheus == true ? 1 : 0
  name             = "monitor"
  namespace        = "monitoring"
  create_namespace = true
  chart            = "${path.module}/charts/kube-prometheus-stack"

  provisioner local-exec {
    command = "kubectl get secret --namespace monitoring monitor-grafana -o jsonpath='{.data.admin-password}' | base64 --decode ; echo > ${path.root}/grafana-admin-key"
  }

  values = [
    file("${path.module}/charts/kube-prometheus-stack/values.yaml")
  ]

  set {
    name  = "prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues"
    value = false
  }

  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = false
  }
}

#resource null_resource grafana-password {
#  count = var.prometheus == true ? 1 : 0
#  depends_on = [
#    helm_release.prometheus
#  ]
#}
#
resource helm_release nginx-controller {
  count            = var.nginx_controller == true ? 1 : 0
  name             = "ingress-nginx"
  namespace        = "nginx"
  create_namespace = true
  chart            = "${path.module}/charts/ingress-nginx"

  values = [
    file("${path.module}/charts/ingress-nginx/values.yaml")
  ]

  #  set {
  #    name  = "default-ssl-certificate"
  #    value = 
  #    #value = var.config_repo
  #  }
}

data kubernetes_service nginx-lb {
  count = var.nginx_controller == true ? 1 : 0
  metadata {
    name      = "${join("", helm_release.nginx-controller[*].name)}-controller"
    namespace = join("", helm_release.nginx-controller[*].namespace)
  }
  depends_on = [
    helm_release.nginx-controller
  ]
}

resource helm_release cert-manager {
  count            = var.cert_manager == true ? 1 : 0
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  chart            = "${path.module}/charts/cert-manager"

  values = [
    file("${path.module}/charts/cert-manager/values.yaml")
  ]

  set {
    name  = "installCRDs"
    value = true
  }

  #  provisioner local-exec {
  #    command = "kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/crds.yaml"
  #  }
}

resource helm_release flux {
  count            = var.flux == true ? 1 : 0
  name             = "flux"
  namespace        = "flux"
  create_namespace = true
  chart            = "${path.module}/charts/flux"
  wait             = true

  values = [
    file("${path.module}/charts/flux/values.yaml")
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
  chart            = "${path.module}/charts/helm-operator"
  wait             = true

  depends_on = [
    helm_release.flux[0]
  ]

  values = [
    file("${path.module}/charts/helm-operator/values.yaml")
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
