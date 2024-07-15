# Despliegue en Kubernetes con microservicios con Docker, PHP, MySQL usando minikube.

Esta guía ofrece un procedimiento detallado para implementar una arquitectura de microservicios empleando Docker, PHP, MySQL y phpMyAdmin en Kubernetes utilizando Minikube.

## Estructura del Proyecto

```plaintext
.
|-- Readme.md
|-- composer.json
|-- kustomization.yaml
|-- mysql
|   |-- deployment-mysql.yaml
|   |-- kustomization.yaml
|   |-- mysqlconfigmap.yaml
|   |-- pv-mysql.yaml
|   |-- pvc-mysql.yaml
|   `-- service-mysql.yaml
|-- phpmyadmin
|   |-- deployment-phpmyadmin.yaml
|   |-- kustomization.yaml
|   `-- service-phpmyadmin.yaml
`-- webapp
    |-- Dockerfile
    |-- deployment-webapp.yaml
    |-- html
    |   |-- index.html
    |   |-- submit.php
    |   `-- vendor
    |       `-- autoload.php
    |-- kustomization.yaml
    `-- service-webapp.yaml

5 directories, 19 files
```

<p><h2>Prerrequisitos</h2>Instalar Minikube y Docker</p>

<h2>Comandos para el despliegue del entorno usando Git bash ¡Resumidos!</h2>

```plaintext
docker context use default
eval $(minikube docker-env)
minikube ip (Sustituir el deployment-webapp.yaml con la ip que sale aqui)
minikube addons enable metrics-server
docker build --tag $(minikube ip):5000/php-webserver .
kubectl apply -k ./
minikube service "servicios" (Creas los servicio)
```

### Descripción de los Archivos de Configuración

#### MySQL

- `configmap.yaml`: Define un ConfigMap que contiene el script SQL para crear la tabla de MySQL.
- `deployment-mysql.yaml`: Define el despliegue del contenedor de MySQL, incluyendo las variables de entorno para las credenciales de la base de datos.
- `kustomization.yaml`: Archivo de Kustomize para gestionar las configuraciones de MySQL.
- `pv-mysql.yaml`: Define un PersistentVolume (PV) para MySQL.
- `pvc-mysql.yaml`: Define un PersistentVolumeClaim (PVC) para MySQL.
- `service-mysql.yaml`: Define un servicio para acceder al contenedor de MySQL.

#### phpMyAdmin

- `deployment-php.yaml`: Define el despliegue del contenedor de phpMyAdmin.
- `kustomization.yaml`: Archivo de Kustomize para gestionar las configuraciones de phpMyAdmin.
- `service-php.yaml`: Define un servicio para acceder al contenedor de phpMyAdmin.

#### webApp

- `Dockerfile`: Define la construcción de la imagen Docker para la aplicación web en PHP.
- `deployment-webapp.yaml`: Define el despliegue del contenedor de la aplicación web.
- `html/index.html`: Página principal de la aplicación web.
- `html/submit.php`: Script PHP para manejar formularios y solicitudes.
- `kustomization.yaml`: Archivo de Kustomize para gestionar las configuraciones de la aplicación web.
- `pvc-webapp.yaml`: Define un PersistentVolumeClaim (PVC) para la aplicación web.
- `service-webapp.yaml`: Define un servicio para acceder al contenedor de la aplicación web.


## Pasos para el Despliegue

### 1. Crear la Imagen Docker para la Aplicación Web en PHP

Navega al directorio `webApp` y crea una imagen Docker:

```bash
eval $(minikube docker-env)
```

```bash
minikube ip
```

Utiliza la dirección IP obtenida del comando `minikube ip` en el siguiente comando `docker build`. Reemplaza `192.168.49.2` con tu IP si es diferente:

```bash
docker build --tag 192.168.49.2:5000/php-webserver .
```

Asegúrate de que el archivo `Dockerfile` esté presente en el directorio `webApp` al ejecutar este comando.

### 2. Aplicar Configuraciones de Kubernetes

Para cada microservicio (MySQL, phpMyAdmin, webApp), aplica las configuraciones de Kubernetes. Puedes hacerlo de varias maneras:

#### Opción 1: Aplicar configuraciones desde la raíz del proyecto

```bash
kubectl apply -k .
```

#### Opción 2: Aplicar configuraciones desde cada carpeta

##### MySQL
  
  ```bash
  cd ../mysql
  kubectl apply -k .
  ```

  ##### phpMyAdmin
  
  ```bash
  cd ../phpmyadmin
  kubectl apply -k .
  ```

  ##### webApp
  
  ```bash
  cd ../webapp
  kubectl apply -k .
  ```

#### Opción 3: Aplicar configuraciones archivo por archivo

```bash
kubectl apply -f <archivo-de-configuración>
```

### 3. Verificar el Despliegue

Verifica el estado de los pods para asegurarte de que estén en ejecución:

```bash
kubectl get pods
```

Deberías ver una salida que indique que todos los pods están en estado `Running`.

### 4. Acceder a los Servicios

#### webApp

Usa el comando `minikube service` para acceder al servicio webApp:
```bash
kubectl get service
```
```bash
minikube service webapp-service
```

#### MySQL y phpMyAdmin

Usa `kubectl port-forward` para acceder a los servicios MySQL y phpMyAdmin:
```bash
kubectl get pods
```
##### MySQL

```bash
kubectl port-forward <nombre-del-pod-mysql> 3306:3306
```

##### phpMyAdmin

```bash
kubectl port-forward <nombre-del-pod-phpmyadmin> 8080:80
```

## Acceder a phpMyAdmin

Las credenciales de usuario y contraseña están definidas en el archivo `deployment-mysql.yaml`. Estas credenciales se pueden cambiar según las necesidades del usuario:

- **Usuario**: `user`
- **Contraseña**: `password`

## Crear una Base de Datos MySQL

Puedes crear una base de datos de varias maneras:

#### 1. Línea de comandos de MySQL

Accede al pod de MySQL y usa el comando `CREATE DATABASE`:

```bash
kubectl exec -it <nombre-del-pod-mysql> -- mysql -u root -p
```

Ingresa la contraseña de root (`admin01` en este caso) y luego ejecuta:

```sql
CREATE DATABASE nombre_de_la_base_de_datos;
```

#### 2. phpMyAdmin

Accede a phpMyAdmin, inicia sesión y usa la interfaz gráfica para crear una base de datos:

1. Abre `http://localhost:8080` en tu navegador.
2. Inicia sesión con las credenciales (`user` y `password`).
3. En la pestaña "Bases de datos", ingresa el nombre de la nueva base de datos y haz clic en "Crear".

#### 3. Archivo de Despliegue

Define la variable `MYSQL_DATABASE` en tu archivo de despliegue de MySQL (`deployment-mysql.yaml`) para crear la base de datos automáticamente:

```yaml
env:
- name: MYSQL_DATABASE
  value: "nombre_de_la_base_de_datos"
```

## Conclusión

Siguiendo los pasos descritos anteriormente, habrás desplegado con éxito una aplicación web en PHP con una base de datos MySQL y phpMyAdmin para la gestión de la base de datos, todo ejecutándose en un clúster de Kubernetes gestionado por Minikube. Esta configuración aprovecha Docker para la contenedorización y Kubernetes para la orquestación, asegurando una arquitectura de microservicios escalable y manejable.

