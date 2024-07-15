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
resource "kubernetes_config_map" "webapp-config" {
  metadata {
    name = "webapp-config"
  }

  data = {
    # Puedes agregar configuraciones específicas aquí si es necesario
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
          image = "your-registry/php-webserver:latest"  # Rellenar con tu registro Docker

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

# Archivo Dockerfile
data "template_file" "dockerfile" {
  template = <<-EOT
    FROM php:8.2-apache

    RUN a2enmod rewrite

    RUN apt-get update \\
        && apt-get install -y libpq-dev \\
        && docker-php-ext-install pdo pdo_pgsql

    RUN docker-php-ext-install mysqli

    WORKDIR /var/www/html

    COPY ./html .

    # Instalar Composer
    COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

    # Instalar dependencias del proyecto
    RUN composer install --no-dev --prefer-dist --optimize-autoloader || true

    EXPOSE 80
  EOT
}

# Construir la imagen Docker
resource "null_resource" "build_docker_image" {
  provisioner "local-exec" {
    command = <<EOT
      echo '${data.template_file.dockerfile.rendered}' | docker build -t your-registry/php-webserver:latest -
    EOT
  }

  depends_on = [data.template_file.dockerfile]
}

# ConfigMap para archivos de la aplicación web
resource "kubernetes_config_map" "webapp-index" {
  metadata {
    name = "webapp-index"
  }

  data = {
    index.html = file("${path.module}/html/index.html")
  }
}

resource "kubernetes_config_map" "webapp-submit" {
  metadata {
    name = "webapp-submit"
  }

  data = {
    submit.php = file("${path.module}/html/submit.php")
  }
}

resource "kubernetes_config_map" "webapp-vendor" {
  metadata {
    name = "webapp-vendor"
  }

  data = {
    autoload.php = file("${path.module}/html/vendor/autoload.php")
  }
}

# Deployment para terraform-example
resource "kubernetes_deployment" "example" {
  metadata {
    name = "terraform-example"
    labels = {
      test = "MyExampleApp"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        test = "MyExampleApp"
      }
    }

    template {
      metadata {
        labels = {
          test = "MyExampleApp"
        }
      }

      spec {
        container {
          image = "miimagen:0.0.2"
          name  = "example"

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }

            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}
