provider "kubernetes" {
  config_path = "~/.kube/config"
}

# ConfigMap para la aplicación web (no se usará directamente en este ejemplo, pero se puede extender)
resource "kubernetes_config_map" "webapp-config" {
  metadata {
    name = "webapp-config"
  }

  data {
    # Puedes agregar configuraciones específicas aquí si es necesario
  }
}

# PersistentVolumeClaim para la aplicación web (si es necesario)
# resource "kubernetes_persistent_volume_claim" "webapp-pvc" {
#   metadata {
#     name = "webapp-pvc"
#   }
#
#   spec {
#     access_modes = ["ReadWriteOnce"]
#
#     resources {
#       requests {
#         storage = "1Gi"
#       }
#     }
#   }
# }

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
        containers {
          name  = "php-webserver"
          image = "your-registry/php-webserver:latest"  # Rellenar con tu registro Docker

          ports {
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

    ports {
      protocol   = "TCP"
      port       = 80
      target_port = 80
    }

    type = "NodePort"
  }
}

# Script de Docker para construir la imagen de la aplicación web
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

# Recurso para ejecutar el script de Docker y construir la imagen
resource "null_resource" "build_docker_image" {
  provisioner "local-exec" {
    command = <<EOT
      echo '${data.template_file.dockerfile.rendered}' | docker build -t your-registry/php-webserver:latest -
    EOT
  }

  depends_on = [data.template_file.dockerfile]
}

# Archivo index.html
resource "kubernetes_config_map" "webapp-index" {
  metadata {
    name = "webapp-index"
  }

  data {
    index.html = file("${path.module}/index.html")
  }
}

# Archivo submit.php
resource "kubernetes_config_map" "webapp-submit" {
  metadata {
    name = "webapp-submit"
  }

  data {
    submit.php = file("${path.module}/submit.php")
  }
}

# Archivo vendor/autoload.php
resource "kubernetes_config_map" "webapp-vendor" {
  metadata {
    name = "webapp-vendor"
  }

  data {
    autoload.php = file("${path.module}/vendor/autoload.php")
  }
}
