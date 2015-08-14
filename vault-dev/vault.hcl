backend "file" {
    path = "/var/opt/vault/data"
}

listener "tcp" {
    address = "0.0.0.0:8200"
    tls_disable = 1 # FIXME just for dev right now, but should be enabled even in dev
}

disable_mlock = true # just for dev to simplify docker executions (not require --cap-add)

