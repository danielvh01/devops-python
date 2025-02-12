provider "kubernetes" {
  config_path = "C:/Users/PC/.kube/config"
}

resource "kubernetes_namespace" "python_api" {
  metadata {
    name = "python-api"
  }
}

resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.python_api.metadata[0].name
  }

  data = {
    APP_ENV = "production"
  }
}

resource "kubernetes_secret" "app_secret" {
  metadata {
    name      = "app-secret"
    namespace = kubernetes_namespace.python_api.metadata[0].name
  }

  data = {
    DATABASE_PASSWORD = "supersecretpassword"
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = "python-api"
    namespace = kubernetes_namespace.python_api.metadata[0].name
    labels = {
      app = "python-api"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "python-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "python-api"
        }
      }

      spec {
        container {
          image = "danielvh01/python_django_api:latest"
          name  = "python-api"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.app_config.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.app_secret.metadata[0].name
            }
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }

          port {
            container_port = 8000
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app_service" {
  metadata {
    name      = "python-api-service"
    namespace = kubernetes_namespace.python_api.metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_deployment.app.metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 8000
    }

    type = "LoadBalancer"
  }
}



resource "kubernetes_horizontal_pod_autoscaler" "app_hpa" {
  metadata {
    name      = "python-api-hpa"
    namespace = kubernetes_namespace.python_api.metadata[0].name
  }

  spec {
    max_replicas = 5
    min_replicas = 2

    scale_target_ref {
      kind = "Deployment"
      name = kubernetes_deployment.app.metadata[0].name
      api_version = "apps/v1"
    }

    target_cpu_utilization_percentage = 50
  }
}
