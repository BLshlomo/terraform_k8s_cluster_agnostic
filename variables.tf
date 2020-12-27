variable dns_addr {
  description = "fronted ingress dns address"
  default     = "Devops2020.ddnsgeek.com"
}

variable nginx_controller {
  description = "Enable nginx controller"
  default     = true
}

variable cert_manager {
  description = "Enable cert-manager controller"
  default     = true
}

variable flux {
  description = "Enable flux operator"
  default     = false
}

variable config_repo {
  description = "flux operator config repo"
  default     = "git@github.com:BLshlomo/chatapp-k8s-fluxcd-config.git"
}

variable logger {
  description = "Enable fluentbit, kibana and es logging stack"
  default     = false
}

variable kubeconfig {
  description = "kubeconfig location path"
}

variable dynu_ip_auth {
  description = "dynu api change ip"
}

variable db_pass {
  description = "chatapp db password access"
}
