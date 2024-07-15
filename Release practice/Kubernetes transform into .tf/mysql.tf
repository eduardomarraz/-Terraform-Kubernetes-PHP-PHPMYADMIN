provider "kubernetes" {
  config_path = "~/.kube/config"
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
    create_table.sql    = <<-EOT
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

# PersistentVolume para MySQL
resource "kubernetes_persistent_volume" "mysql-pv" {
  metadata {
    name = "mysql-pv"
  }

  spec {
    capacity {
      storage = "1Gi"
    }

    access_modes = ["ReadWriteOnce"]

    persistent_volume_source {
      host_path {
        path = "/mnt/data"
      }
    }
  }
}

# PersistentVolumeClaim para MySQL
resource "kubernetes_persistent_volume_claim" "mysql-pvc" {
  metadata {
    name = "mysql-pvc"
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests {
        storage = "1Gi"
      }
    }
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
        containers {
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

          ports {
            container_port = 3306
          }

          volume_mount {
            name       = "mysql-persistent-storage"
            mount_path = "/var/lib/mysql"
          }
        }

        volume {
          name = "mysql-persistent-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.mysql-pvc.metadata[0].name
          }
        }

        volume {
          name = "mysqlconfigmap"
          config_map {
            name = kubernetes_config_map.mysqlconfigmap.metadata[0].name

            item {
              key  = "create_table.sql"
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
