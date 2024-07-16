provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

# ConfigMap para MySQL
resource "kubernetes_config_map" "mysqlconfigmap" {
  metadata {
    name = "mysqlconfigmap"
  }

  data = {
    MYSQL_ROOT_PASSWORD = "root"
    MYSQL_DATABASE      = "database"
    MYSQL_USER          = "user"
    MYSQL_PASSWORD      = "password"
    create_table_sql    = <<-EOT
      CREATE TABLE IF NOT EXISTS form_data (
          id INT AUTO_INCREMENT PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          email VARCHAR(255) NOT NULL,
          message TEXT NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    EOT
  }
}

# Deployment para MySQL
resource "kubernetes_deployment" "mysql" {
  metadata {
    name = "mysql"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mysql"
      }
    }

    template {
      metadata {
        labels = {
          app = "mysql"
        }
      }

      spec {
        container {
          name  = "mysql"
          image = "mysql:5.7"

          env {
            name = "MYSQL_ROOT_PASSWORD"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.mysqlconfigmap.metadata[0].name
                key  = "MYSQL_ROOT_PASSWORD"
              }
            }
          }

          env {
            name = "MYSQL_DATABASE"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.mysqlconfigmap.metadata[0].name
                key  = "MYSQL_DATABASE"
              }
            }
          }

          env {
            name = "MYSQL_USER"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.mysqlconfigmap.metadata[0].name
                key  = "MYSQL_USER"
              }
            }
          }

          env {
            name = "MYSQL_PASSWORD"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.mysqlconfigmap.metadata[0].name
                key  = "MYSQL_PASSWORD"
              }
            }
          }

          port {
            container_port = 3306
          }
        }

        volume {
          name = "mysqlconfigmap"
          config_map {
            name = kubernetes_config_map.mysqlconfigmap.metadata[0].name

            items {
              key  = "create_table_sql"
              path = "create_table.sql"
            }
          }
        }
      }
    }
  }
}

# Service para MySQL
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

# ConfigMap para la aplicación web
resource "kubernetes_config_map" "webapp-index" {
  metadata {
    name = "webapp-index"
  }

  data = {
    "index.html" = file("${path.module}/html/index.html")
  }
}

# Deployment para la aplicación web
resource "kubernetes_deployment" "webapp" {
  metadata {
    name = "php-webserver"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "php-webserver"
      }
    }

    template {
      metadata {
        labels = {
          app = "php-webserver"
        }
      }

      spec {
        container {
          name  = "php-webserver"
          image = "php-webserver:latest"  # Usar la imagen local construida con Minikube

          port {
            container_port = 80
          }

          env {
            name  = "MYSQL_HOST"
            value = kubernetes_service.mysql.metadata[0].name  # Nombre del servicio MySQL
          }

          env {
            name  = "MYSQL_USER"
            value = "user"
          }

          env {
            name  = "MYSQL_PASSWORD"
            value = "password"
          }

          env {
            name  = "MYSQL_DATABASE"
            value = "database"
          }
        }
      }
    }
  }

  depends_on = [null_resource.build_docker_image]
}

# Service para la aplicación web
resource "kubernetes_service" "webapp" {
  metadata {
    name = "php-webserver"
  }

  spec {
    selector = {
      app = "php-webserver"
    }

    port {
      protocol   = "TCP"
      port       = 80
      target_port = 80
    }

    type = "NodePort"
  }
}

# Construir la imagen Docker
resource "null_resource" "build_docker_image" {
  provisioner "local-exec" {
    command = "eval $(minikube docker-env) && docker build -t php-webserver:latest ."
  }

  # No se necesita depends_on aquí, ya que el comando se ejecuta localmente
}
