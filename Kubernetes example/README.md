# Despliegue de Recursos en Kubernetes con Minikube y Terraform

```sh
# Prerrequisitos

# 1. Instalar Terraform en Windows.
# 2. Tener Docker iniciado en Windows y ejecutar el comando:
docker context use default

# Pasos

# 1. Iniciar Minikube:
minikube start

# 2. Situarse en el directorio donde tienes los archivos:
# |-- k8s.tf
# |-- providers.tf

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