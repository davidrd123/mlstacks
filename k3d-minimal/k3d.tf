resource "random_string" "cluster_id" {
  length  = 6
  special = false
  upper   = false
}

resource "k3d_cluster" "zenml-cluster" {
  name    = "${local.k3d.cluster_name}-${random_string.cluster_id.result}"
  servers = 1
  agents  = 2
  
  kube_api {
    host      = "${local.k3d_kube_api.host}"
    host_ip   = "127.0.0.1"
  }

  image   = "${local.k3d.image}"

  registries {
    create {
      name      = "${local.k3d_registry.name}-${random_string.cluster_id.result}"
      host      = "${local.k3d_registry.host}"
      image     = "docker.io/registry:2"
      host_port = "${local.k3d_registry.port}"
    }
  }

  k3d {
    disable_load_balancer     = false
    disable_image_volume      = false
  }

  kubeconfig {
    update_default_kubeconfig = true
    switch_current_context    = true
  }
}