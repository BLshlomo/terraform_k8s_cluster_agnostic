#resource kubernetes_secret mongo-echo {
#  metadata {
#    name = "echo-mongo"
#  }
#
#  data = {
#    mongodburl = var.muri
#  }
#}
#
#resource kubernetes_secret dev-mongo-echo {
#  metadata {
#    name = "echo-mongo"
#    namespace = "dev"
#  }
#
#  data = {
#    mongodburl = var.muri
#  }
#}
#
#resource kubernetes_secret prod-mongo-echo {
#  metadata {
#    name = "echo-mongo"
#    namespace = "production"
#  }
#
#  data = {
#    mongodburl = var.muri
#  }
#}
#
#resource kubernetes_secret stag-mongo-echo {
#  metadata {
#    name = "echo-mongo"
#    namespace = "staging"
#  }
#
#  data = {
#    mongodburl = var.muri
#  }
#}
#
#resource kubernetes_secret mongo-secret {
#  metadata {
#    name = "mongodb"
#  }
#
#  data = {
#    user = var.muser
#    password = var.mpass
#  }
#}
#
#resource kubernetes_secret clouddns-secret {
#  metadata {
#    name = "clouddns-dns01-solver-svc-acct"
#    namespace = "cert-manager"
#  }
#  data = {
#    "key.json" = data.terraform_remote_state.gke.outputs.clouddns-key
#    #base64decode(data.terraform_remote_state.gke.outputs.clouddns-key)
#  }
#}
#
#resource helm_release cert-manager {
#  name  = "cert-manager"
#  chart = "./charts/cert-manager"
#  namespace = "cert-manager"
#  create_namespace = true
#
#  values = [
#    "${file("./charts/cert-manager/values.yaml")}"
#  ]
#}
#
#
#resource helm_release mongo {
#  name  = "mongo"
#  chart = "./charts/mongodb-replicaset"
#
#  values = [
#    "${file("./charts/mongodb-replicaset/values.yaml")}"
#  ]
#}
#
#resource helm_release echoapp {
#  name  = "echoapp"
#  chart = "./charts/conf-repo/mychart"
#
#  values = [
#    "${file("./charts/conf-repo/mychart/values.yaml")}"
#  ]
#}
#
#resource helm_release prod_mongo {
#  name  = "mongo"
#  chart = "./charts/mongodb-replicaset"
#  namespace = "production"
#  create_namespace = false
#
#  values = [
#    "${file("./charts/mongodb-replicaset/values.yaml")}"
#  ]
#}
#

#resource "kubernetes_service" "example" {
#  metadata {
#    name = "terraform-example"
#  }
#  spec {
#    selector = {
#      app = "${kubernetes_pod.example.metadata.0.labels.app}"
#    }
#    session_affinity = "ClientIP"
#    port {
#      port        = 8080
#      target_port = 80
#    }
#
#    type = "LoadBalancer"
#  }
#}
#
resource helm_release nginx-controller {
  count = var.nginx_controller == true ? 1 : 0
  name  = "ingress-nginx"
  chart = "${path.module}/new/ingress-nginx"

  values = [
    file("${path.module}/new/ingress-nginx/values.yaml")
  ]
}

data kubernetes_service nginx-lb {
  count = var.nginx_controller == true ? 1 : 0
  metadata {
    name      = "${helm_release.nginx-controller[0].name}-controller"
    namespace = helm_release.nginx-controller[0].namespace
  }
}

output nginx-lb-ip {
  value = data.kubernetes_service.nginx-lb[0].load_balancer_ingress[*].ip
}
#
#resource helm_release fluxcd {
#  name  = "flux"
#  chart = "fluxcd/flux"
#  #repository = "https://charts.fluxcd.io"
#  namespace = "fluxcd"
#  create_namespace = true
#  wait = true
#
#  set {
#    name  = "git.url"
#    value = "git@github.com:BLsolomon/fluxcd-config-repo.git"
#  }
#}
#
#resource helm_release fluxcd-chart {
#  name  = "flux-chart"
#  chart = "fluxcd/helm-operator"
#  #repository = "https://charts.fluxcd.io"
#  namespace = "fluxcd"
#  create_namespace = true
#
#  set {
#    name  = "git.ssh.secretName"
#    value = "flux-git-deploy"
#  }
#
#  set {
#    name  = "helm.versions"
#    value = "v3"
#  }
#}
#
#resource helm_release logger {
#  name  = "logger"
#  chart = "/home/Admin/docker/ke/22_efk_echo/kube-logging/"
#}
