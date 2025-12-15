Inception

El objetivo de este proyecto es desplegar una infraestructura completa de servicios web utilizando << Docker >> y << Docker Compose >>, respetando estrictamente las reglas del subject: aislamiento de servicios, uso de imágenes propias, seguridad mediante secrets y persistencia de datos mediante volúmenes.

## Servicios incluidos

### Obligatorios

* << NGINX >> -> Reverse proxy HTTPS (TLSv1.2 / TLSv1.3)
* << WordPress >> -> PHP-FPM
* << MariaDB >> -> Base de datos

### Bonus

* << Redis >> -> Caché de objetos para WordPress
* << FTP >> -> Subida de archivos al volumen de WordPress
* << Adminer >> -> Gestión visual de MariaDB
* << Static Website >> -> Web estática independiente
* << cAdvisor >> -> Monitorización de contenedores

---

## Estructura del proyecto

--- README.md
|-- Makefile
|-- secrets
|-- srcs
|   |-- docker-compose.yml
|   `-- requirements
|       |-- mariadb
|       |-- nginx
|       |-- wordpress
|       `-- bonus
|           |-- redis
|           |-- ftp
|           |-- static_website
|           |-- adminer
|           `-- cadvisor

---

## Makefile

### ¿Qué es?

Archivo que define comandos personalizados para gestionar todo el proyecto de forma sencilla.

### Comandos principales

* **`make` / `make up`**

  * Crea directorios de datos persistentes
  * Ajusta permisos
  * Construye imágenes Docker
  * Arranca los contenedores

* **`make down`**

  * Detiene los contenedores sin borrar datos

* **`make clean`**

  * Detiene y elimina contenedores
  * Mantiene volúmenes

* **`make fclean`**

  * Elimina contenedores, imágenes y volúmenes
  * Borra completamente `/home/<user>/data`

* **`make re`**

  * Reinicio completo (`fclean` + `up`)

---

## secrets

Carpeta que contiene << información sensible >>.

 # Nunca se sube a Git.

Ejemplos de archivos:

* `db_root_password.txt`
* `db_password.txt`
* `wp_admin_password.txt`
* `wp_user_password.txt`
* `ftp_user_password.txt`

Cada archivo contiene una única línea con la contraseña correspondiente.

Los secretos se inyectan en los contenedores mediante << Docker secrets >>, cumpliendo las normas del subject.

---

## docker-compose.yml

Archivo central de orquestación.

Define:

* Servicios
* Redes internas
* Volúmenes persistentes
* Dependencias entre contenedores
* Uso de secrets

Permite levantar toda la infraestructura con:

```
    - bash -
 << make up >>
```

---

## MariaDB

Servicio de base de datos.

### Componentes

* **Dockerfile**

  * Imagen basada en Debian (penúltima versión estable)
  * Instalación de MariaDB

* **my.cnf**

  * Configuración personalizada del servidor

* **entrypoint.sh**

  * Inicializa la base de datos
  * Crea usuarios y permisos
  * Usa contraseñas desde `/run/secrets`
  * Evita reinicializar si ya existen datos

Datos persistentes almacenados en un volumen del host.

---

## NGINX

Actúa como << único punto de entrada >> a la infraestructura.

### Funciones

* HTTPS obligatorio
* Certificados TLS autofirmados
* Reverse proxy hacia WordPress (PHP-FPM)

### Componentes

* **Dockerfile**
* **default.conf.template**
* **nginx_entrypoint.sh**
* **generate_certs.sh**

NGINX se ejecuta en primer plano para mantener el contenedor activo.

---

## 📝 WordPress

Ejecutado con **PHP-FPM**, sin servidor web integrado.

### Funciones

* Instalación automática con WP-CLI
* Creación de usuarios
* Configuración automática de Redis

### Componentes

* **Dockerfile**
* **php.ini**
* **[www.conf](http://www.conf)**
* **wordpress_entrypoint.sh**

WordPress espera a que MariaDB esté disponible antes de instalarse.

---

## ⭐ Bonus

### Redis

* Caché de objetos
* Mejora el rendimiento de WordPress

### FTP

* Acceso FTP al volumen de WordPress
* Permite subir archivos desde el host

### Adminer

* Interfaz web para MariaDB

### Static Website

* Web estática independiente

### cAdvisor

* Monitorización de contenedores
* Métricas de CPU, memoria y disco

---

## Red y volúmenes

* Red Docker interna tipo `bridge`
* Volúmenes montados en el host:

  * MariaDB
  * WordPress
  * Redis

Garantiza persistencia incluso tras reiniciar contenedores.

---

## 🚀 Uso rápido

```
    - bash -
 << make up >>
```

make up     # Arrancar proyecto
make down   # Detener contenedores
make re     # Reinicio completo

```

---
