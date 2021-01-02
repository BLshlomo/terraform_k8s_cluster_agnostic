terraform {
  backend gcs {
    bucket = "devel-tfstate"
    prefix = "terraform/state/k8s"
  }
}

locals {
  region  = "europe-west2"
  zone    = "europe-west2-c"
  project = "devel-final"
}

data terraform_remote_state gke {
  backend = "gcs"
  config = {
    bucket = "devel-tfstate"
    prefix = "terraform/state/gke"
  }
}

provider google {
  version = "~> 3.35"
  project = local.project
  region  = local.region
  zone    = local.zone
}

# Retrieve an access token as the Terraform runner
data google_client_config provider {}

data google_container_cluster my_cluster {
  name     = data.terraform_remote_state.gke.outputs.cluster-name
  location = local.zone
}

provider kubernetes {
  load_config_file = true
  version          = "~> 1.13"

  config_path = var.kubeconfig

  #  host = "https://${data.google_container_cluster.my_cluster.endpoint}"
  #  #token = data.google_client_config.provider.access_token
  #  cluster_ca_certificate = base64decode(
  #    data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate,
  #  )
  #  client_certificate = base64decode(
  #    data.google_container_cluster.my_cluster.master_auth[0].client_certificate,
  #  )
  #  client_key = base64decode(
  #    data.google_container_cluster.my_cluster.master_auth[0].client_key,
  #  )
}

provider "helm" {
  version = "~> 1.3"
  kubernetes {
    config_path = var.kubeconfig

    #    host  = "https://${data.google_container_cluster.my_cluster.endpoint}"
    #    token = data.google_client_config.provider.access_token
    #    cluster_ca_certificate = base64decode(
    #      data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate,
    #    )
  }
}

provider null {
  version = "~> 3.0"
}

module cluster_management {
  source           = "./modules/cluster_management"
  logger           = var.logger
  prometheus       = var.prometheus
  nginx_controller = var.nginx_controller
  cert_manager     = var.cert_manager
  flux             = var.flux
  config_repo      = var.config_repo
}

resource null_resource set-dns {
  count = var.nginx_controller == true ? 1 : 0
  depends_on = [
    module.cluster_management.nginx-lb-ip
  ]

  triggers = {
    lb-ip = join("", module.cluster_management.nginx-lb-ip[0])
  }

  provisioner local-exec {
    command = "echo ${self.triggers.lb-ip} && echo \"ip = $ip\" && [ `echo ${self.triggers.lb-ip} | wc -m` -gt 2 -a '${self.triggers.lb-ip}' != \"$ip\" ] && ip='${self.triggers.lb-ip}' && curl -X GET 'https://api.dynu.com/nic/update?hostname=${var.dns_addr}&myip=${self.triggers.lb-ip}' -H \"Authorization: Basic ${var.dynu_ip_auth}\" || exit 0"
  }
}

resource helm_release mysql {
  count            = 0
  name             = "mysql"
  chart            = "${path.root}/deploy/mysql"
  namespace        = "production"
  create_namespace = true
  wait             = true

  values = [
    file("${path.root}/deploy/mysql/values-production.yaml")
  ]

  set {
    name  = "metrics.serviceMonitor.namespace"
    value = "monitoring"
  }

  set {
    name  = "metrics.serviceMonitor.enabled"
    value = true
  }

  set {
    name  = "auth.forcePassword"
    value = false
  }

  set {
    name  = "auth.usePasswordFiles"
    value = false
  }

  set {
    name  = "auth.customPasswordFiles"
    value = ""
  }

  set {
    name  = "primary.persistence.enabled"
    value = false
  }

  set {
    name  = "secondary.persistence.enabled"
    value = false
  }

  set {
    name  = "auth.database"
    value = "chat"
  }

  set {
    name  = "auth.username"
    value = "chat"
  }

  set {
    name  = "auth.password"
    value = var.prod_db_pass
  }
}

resource helm_release mysql-staging {
  count            = 0
  name             = "mysql-staging"
  chart            = "${path.root}/deploy/mysql-dev"
  namespace        = "staging"
  create_namespace = true
  wait             = true

  values = [
    file("${path.root}/deploy/mysql-dev/values.yaml")
  ]

  set {
    name  = "mysqlPassword"
    value = var.stg_db_pass
  }
}
