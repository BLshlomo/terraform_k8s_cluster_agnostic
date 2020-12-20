variable nginx_controller {
  description = "Enable nginx controller"
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

variable logger {
  description = "Enable fluentbit, kibana and es logging stack"
  type        = bool
}
