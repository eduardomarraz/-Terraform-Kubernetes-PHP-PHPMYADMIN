

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

# Service para MySQL (necesario para phpMyAdmin)
resource "kubernetes_service" "mysql" {
  metadata {
    name = "mysql"
  }

  spec {
    selector = {
      app = "mysql"
    }

    port {
      port        = 3306
      target_port = 3306
    }

    cluster_ip = "None"
  }
}

# Deployment para phpMyAdmin
resource "kubernetes_deployment" "phpmyadmin" {
  metadata {
    name = "phpmyadmin"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "phpmyadmin"
      }
    }

    template {
      metadata {
        labels = {
          app = "phpmyadmin"
        }
      }

      spec {
        container {
          name  = "phpmyadmin"
          image = "phpmyadmin/phpmyadmin"
          image_pull_policy = "IfNotPresent"

          env {
            name  = "PMA_HOST"
            value = kubernetes_service.mysql.metadata[0].name  # Nombre del servicio MySQL
          }

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# Service para phpMyAdmin
resource "kubernetes_service" "phpmyadmin" {
  metadata {
    name = "phpmyadmin"
  }

  spec {
    selector = {
      app = "phpmyadmin"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}
