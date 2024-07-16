# Despliegue de Recursos en Kubernetes con Minikube y Terraform

```sh
# Prerrequisitos

# Instalar Terraform en Windows.
https://developer.hashicorp.com/terraform/install

# Pasos

# 1. Iniciar Minikube:
minikube start
docker context use default
eval $(minikube docker-env)             # Unix shells
minikube docker-env | Invoke-Expression # PowerShell
docker build -t php-webserver:latest .  # Realizar el comando situandose en el Dockerfile.

# 2. Situarse en el directorio donde tienes los archivos, (Tengo dividido los microservicios
# funcionando individualmente en tres carpetas: Phpmyadmin, Phpmyadmin & MySQL y Phpmyadmin & MySQL & webapp).
`-- Release practice
    |-- Kubernetes transform into .tf
    |   |-- main.tf
    |   |-- mysql.tf
    |   |-- phpmyadmin.tf
    |   `-- webapp.tf
    `-- Microservices working together
        |-- Phpmyadmin
        |   `-- main_1.tf
        |-- Phpmyadmin & MySQL
        |   `-- main_2_servicios.tf
        `-- Phpmyadmin & MySQL & webapp
            |-- Dockerfile
            |-- html
            |   |-- index.html
            |   |-- submit.php
            |   `-- vendor
            |       `-- autoload.php
            `-- main_3_entero.tf


# 3. Inicializar Terraform:
terraform init

# 4. Aplicar la configuración de Terraform:
terraform apply

# 5. Redirigir los puertos para acceder a la aplicación utilizando `kubectl` o usando minikube.
# Con kubectl
kubectl port-forward -n phpmyadmin-example-7997bdd7d7-5qc4t 8080:80

# Con minikube service pod
minikube service phpmyadmin

```