variable logger {
  description = "Enable fluentbit, kibana and es logging stack"
  type        = bool
}

variable prometheus {
  description = "Enable prometheus monitoring"
  type        = bool
}

variable nginx_controller {
  description = "Enable nginx controller"
  type        = bool
}

variable cert_manager {
  description = "Enable cert-manager controller"
  type        = bool
}

variable flux {
  description = "Enable flux operator"
  type        = bool
}

variable config_repo {
  description = "flux operator config repo"
  type        = string
}
