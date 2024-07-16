# Despliegue de Recursos en Kubernetes con Minikube y Terraform

```sh
# Prerrequisitos

# 1. Instalar Terraform en Windows.
# 2. Tener Docker iniciado en Windows y ejecutar el comando:
docker context use default

# Pasos

# 1. Iniciar Minikube:
minikube start
eval $(minikube docker-env)             # Unix shells
minikube docker-env | Invoke-Expression # PowerShell
docker build -t php-webserver:latest .

# 2. Situarse en el directorio donde tienes los archivos, (Tengo dividido los microservicios funcionando individualmente en tres carpetas: Phpmyadmin, Phpmyadmin & MySQL y Phpmyadmin & MySQL & webapp):
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

# 5. Exponer el pod utilizando `kubectl`:
kubectl expose pod terraform-example-7997bdd7d7-5qc4t -n k8s-ns-by-tf --type=NodePort --port=8080

# 6. Redirigir los puertos para acceder a la aplicación:
kubectl port-forward -n k8s-ns-by-tf terraform-example-7997bdd7d7-5qc4t 8080:80

# Esto te permitirá correr Nginx en el puerto 8080.
```