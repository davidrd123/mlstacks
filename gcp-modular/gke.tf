data "google_client_config" "default" {}
# module "gke" {
#   count = (var.enable_kubeflow || var.enable_tekton || var.enable_kubernetes || 
#             var.enable_kserve || var.enable_seldon || var.enable_mlflow ||
#             var.enable_zenml)? 1: 0
          
#   depends_on = [
#     google_project_service.compute_engine_api
#   ]

#   source            = "terraform-google-modules/kubernetes-engine/google"
#   project_id        = local.project_id
#   name              = "${local.prefix}-${local.gke.cluster_name}"
#   region            = local.region
#   zones             = ["${local.region}-a", "${local.region}-b", "${local.region}-c"]
#   network           = module.vpc.network_name
#   subnetwork        = module.vpc.subnets_names[0]
#   ip_range_pods     = "gke-pods"
#   ip_range_services = "gke-services"

#   kubernetes_version         = local.gke.cluster_version
#   http_load_balancing        = false
#   network_policy             = false
#   horizontal_pod_autoscaling = true
#   filestore_csi_driver       = false

#   node_pools = [
#     {
#       name            = "default-node-pool"
#       machine_type    = "e2-standard-8"
#       node_locations  = "${local.region}-b"
#       min_count       = 1
#       max_count       = 3
#       local_ssd_count = 0
#       disk_size_gb    = 100
#       disk_type       = "pd-standard"
#       image_type      = "COS_CONTAINERD"
#       enable_gcfs     = false
#       auto_repair     = true
#       auto_upgrade    = true
#       service_account = google_service_account.gke-service-account[0].email

#       preemptible        = false
#       initial_node_count = 1
#     },
#   ]

#   node_pools_oauth_scopes = {
#     all = []

#     default-node-pool = [
#       "https://www.googleapis.com/auth/cloud-platform",
#     ]
#   }

#   node_pools_labels = {
#     all = {}

#     default-node-pool = {
#       default-node-pool = true
#     }
#   }
# }
data "google_container_cluster" "my_cluster" {
  name     = "${local.prefix}-${local.gke.cluster_name}"
  location = local.region

  depends_on = [
    google_container_cluster.gke
  ]
}

resource "google_container_cluster" "gke" {
  count = (var.enable_kubeflow || var.enable_tekton || var.enable_kubernetes || 
            var.enable_kserve || var.enable_seldon || var.enable_mlflow ||
            var.enable_zenml)? 1: 0

  name               = "${local.prefix}-${local.gke.cluster_name}"
  project            = local.project_id

  location           = local.region
  node_locations     = ["${local.region}-a", "${local.region}-b", "${local.region}-c"]
  initial_node_count = 1

  network = module.vpc.network_name
  subnetwork = module.vpc.subnets_names[0]
  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }
  node_config {
    machine_type = "e2-standard-8"
    
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.gke-service-account[0].email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  timeouts {
    create = "30m"
    update = "40m"
  }

  depends_on = [
    google_project_service.compute_engine_api
  ]
}

# service account for GKE nodes
resource "google_service_account" "gke-service-account" {
  count = (var.enable_kubeflow || var.enable_tekton || var.enable_kubernetes || 
            var.enable_kserve || var.enable_seldon || var.enable_mlflow ||
            var.enable_zenml)? 1: 0
  account_id   = "${local.prefix}-${local.gke.service_account_name}"
  project      = local.project_id
  display_name = "Terraform GKE SA"
}

resource "google_project_iam_binding" "container-registry" {
  count = length(google_container_cluster.gke)
  project = local.project_id
  role    = "roles/containerregistry.ServiceAgent"

  members = [
    "serviceAccount:${google_service_account.gke-service-account[0].email}",
  ]
}

resource "google_project_iam_binding" "secret-manager" {
  count = (var.enable_kubeflow || var.enable_tekton || var.enable_kubernetes || 
            var.enable_kserve || var.enable_seldon || var.enable_mlflow ||
            var.enable_zenml)? 1: 0
  project = local.project_id
  role    = "roles/secretmanager.admin"

  members = [
    "serviceAccount:${google_service_account.gke-service-account[0].email}",
  ]
}

resource "google_project_iam_binding" "cloudsql" {
  count = (var.enable_kubeflow || var.enable_tekton || var.enable_kubernetes || 
            var.enable_kserve || var.enable_seldon || var.enable_mlflow ||
            var.enable_zenml)? 1: 0
  project = local.project_id
  role    = "roles/cloudsql.admin"

  members = [
    "serviceAccount:${google_service_account.gke-service-account[0].email}",
  ]
}

resource "google_project_iam_binding" "storageadmin" {
  count = (var.enable_kubeflow || var.enable_tekton || var.enable_kubernetes || 
            var.enable_kserve || var.enable_seldon || var.enable_mlflow ||
            var.enable_zenml)? 1: 0
  project = local.project_id
  role    = "roles/storage.admin"

  members = [
    "serviceAccount:${google_service_account.gke-service-account[0].email}",
  ]
}

resource "google_project_iam_binding" "vertex-ai-user" {
  count = (var.enable_kubeflow || var.enable_tekton || var.enable_kubernetes || 
            var.enable_kserve || var.enable_seldon || var.enable_mlflow ||
            var.enable_zenml)? 1: 0
  project = local.project_id
  role    = "roles/aiplatform.user"

  members = [
    "serviceAccount:${google_service_account.gke-service-account[0].email}",
  ]
}
