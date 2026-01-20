Inception

El objetivo de este proyecto es desplegar una infraestructura completa de servicios web `Simular cómo funciona una página web REAL por dentro ` utilizando ` Docker ` y ` Docker Compose `, respetando estrictamente las reglas del subject: aislamiento de servicios, uso de imágenes propias, seguridad mediante secrets y persistencia de datos mediante volúmenes.

## Servicios incluidos

### Obligatorios

* << NGINX >>       => Reverse proxy HTTPS (TLSv1.2 / TLSv1.3)
* << WordPress >>   => PHP-FPM
* << MariaDB >>     => Base de datos

---

### Bonus

* << Redis >>           => Caché de objetos para WordPress
* << FTP >>             => Subida de archivos al volumen de WordPress
* << Adminer >>         => Gestión visual de MariaDB
* << Static Website >>  => Web estática independiente
* << cAdvisor >>        => Monitorización de contenedores

---

## Estructura del proyecto

```text
|-- README.md
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
```

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

Carpeta que contiene las contraseñas que se requieren en el proyecto .

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
Es un archivo que le dice a Docker "Quiero varios contenerdore, que trabajen juntos, de esta forma".  
No ejecuta programas por si mismo, solo ejecuta.

Define:

* Servicios
* Redes internas
* Volúmenes persistentes
* Dependencias entre contenedores
* Uso de secrets

Permite levantar toda la infraestructura con:

```bash
 << make up >>
```

---

## MariaDB

Servicio de base de datos relacional encargado de almacenar toda la información de WordPress
(usuarios, posts, configuraciones, plugins, etc.).

MariaDB se ejecuta en su propio contenedor, sin NGINX, y se comunica únicamente a través de la
red interna de Docker definida en el proyecto.

### Componentes

* **Dockerfile**

  * Imagen basada en **Debian bookworm** (penúltima versión estable), cumpliendo los requisitos del subject.
  * Instala únicamente `mariadb-server` y dependencias mínimas para reducir el tamaño de la imagen.
  * Copia el archivo de configuración `my.cnf` dentro del contenedor.
  * Copia el script `mariadb_entrypoint.sh`, que se encarga de la inicialización.
  * Expone el puerto **3306**, utilizado internamente por WordPress para conectarse a la base de datos.
  * Define el `ENTRYPOINT` para que MariaDB se ejecute correctamente como proceso principal (PID 1).

* **my.cnf**

  * Archivo de configuración personalizado de MariaDB.
  * Ajustes principales:
    * Charset y collation `utf8mb4` para compatibilidad total con WordPress.
    * Uso de **InnoDB** como motor de almacenamiento (recomendado para WordPress).
    * Configuración de memoria y conexiones optimizada para entorno Docker.
    * `bind-address = 0.0.0.0` para permitir conexiones desde otros contenedores de la red.
  * Permite un funcionamiento estable y predecible dentro de contenedores.

* **entrypoint.sh**

  * Script ejecutado al iniciar el contenedor.
  * Funciones principales:
    * Crear los directorios necesarios y asegurar permisos correctos.
    * Detectar si la base de datos ya ha sido inicializada.
    * Inicializar MariaDB solo en el primer arranque del contenedor.
    * Crear la base de datos de WordPress.
    * Crear el usuario normal y el usuario administrador con los permisos adecuados.
    * Leer todas las contraseñas desde **Docker secrets** (`/run/secrets`).
    * Evitar la reinicialización si los datos ya existen, garantizando persistencia.
  * Arranca MariaDB en primer plano para cumplir con las buenas prácticas de Docker.

### Persistencia de datos

Los datos de MariaDB se almacenan en un **volumen Docker** montado en el host:


Esto permite que:
- Los datos sobrevivan a reinicios del contenedor.
- No se pierda información al reconstruir las imágenes.
- Se cumpla el requisito de persistencia del proyecto Inception.

### Seguridad

- No hay contraseñas escritas en el Dockerfile ni en `docker-compose.yml`.
- Todas las credenciales se gestionan mediante **Docker secrets**.
- El contenedor solo es accesible desde la red interna de Docker, nunca directamente desde el exterior.


---


## NGINX

Servicio encargado de actuar como **servidor web** y **reverse proxy** del proyecto.
Es el **único contenedor expuesto al exterior**, cumpliendo estrictamente el subject de Inception.

NGINX se encarga de:
- Gestionar conexiones **HTTPS**.
- Servir contenido estático.
- Redirigir peticiones PHP a WordPress mediante **FastCGI**.
- Aplicar configuración de seguridad TLS.

### Componentes

* **Dockerfile**

  * Imagen basada en **Debian bookworm** (penúltima versión estable).
  * Instala únicamente:
    * `nginx`
    * `openssl` (para certificados TLS)
  * Copia archivos de configuración personalizados.
  * Copia el script de generación de certificados.
  * Usa un `ENTRYPOINT` para inicializar certificados y arrancar NGINX.
  * Ejecuta NGINX en primer plano (`daemon off;`) como proceso principal.

* **default.conf.template**

  * Archivo de configuración principal del servidor virtual.
  * Utiliza variables de entorno (ej. `DOMAIN_NAME`) que se sustituyen en tiempo de ejecución.
  * Define:
    * Puerto **443** con HTTPS.
    * Certificados TLS.
    * Redirección de peticiones PHP hacia WordPress.
  * Ejemplo de responsabilidades:
    * `root /var/www/html;`
    * `index index.php index.html;`
    * Bloque `location ~ \.php$` con FastCGI hacia WordPress.
    * Protección frente a acceso directo a archivos sensibles.

* **nginx.conf**

  * Configuración global de NGINX.
  * Define:
    * Usuario de ejecución (`www-data`).
    * Número de workers automáticos.
    * Optimización de eventos y conexiones.
  * Incluye el archivo `default.conf` para los virtual hosts.
  * Mejora el rendimiento y estabilidad del servidor.

* **generate_certs.sh**

  * Script encargado de generar certificados **SSL/TLS autofirmados**.
  * Crea:
    * Clave privada (`.key`)
    * Certificado (`.crt`)
  * Utiliza el dominio definido en variables de entorno.
  * Evita regenerar certificados si ya existen.
  * Permite cumplir el requisito HTTPS sin depender de servicios externos.

* **nginx_entrypoint.sh**

  * Script de arranque del contenedor.
  * Funciones principales:
    * Sustituir variables de entorno dentro de `default.conf.template`.
    * Verificar la existencia de certificados TLS.
    * Lanzar NGINX en primer plano.
  * Asegura que la configuración sea dinámica y reutilizable.

### Configuración HTTPS (TLS)

- NGINX usa **TLSv1.2 y TLSv1.3**.
- El puerto **443** es el único expuesto al exterior.
- Certificados cargados desde Docker secrets:
  - `/run/secrets/nginx.crt`
  - `/run/secrets/nginx.key`
- El tráfico HTTP sin cifrar **no está permitido**.

### Comunicación con WordPress

NGINX se comunica con WordPress mediante **FastCGI**:

- Host: `wordpress`
- Puerto: `9000`
- Protocolo: FastCGI
- No ejecuta PHP directamente.

Esto permite:
- Separación clara de responsabilidades.
- Mayor seguridad.
- Escalabilidad futura.

### Volúmenes

- Comparte el volumen `wordpress_data`:

- Permite servir:
- Archivos PHP
- Recursos estáticos (CSS, JS, imágenes)

### Seguridad

- NGINX es el único punto de entrada externo.
- No se ejecuta como root.
- No expone información de versiones.
- Bloquea acceso a archivos ocultos y sensibles.
- Uso exclusivo de HTTPS.


---


## WordPress + PHP-FPM

Servicio encargado de ejecutar WordPress utilizando **PHP-FPM** como motor de ejecución PHP.
Este contenedor **no incluye NGINX**, cumpliendo estrictamente con los requisitos del subject:
NGINX actúa como proxy inverso desde otro contenedor.

WordPress se comunica con:
- **MariaDB** para el almacenamiento de datos.
- **NGINX** mediante FastCGI (puerto 9000).
- **Redis** (bonus) para cacheo de objetos.

### Componentes

* **Dockerfile**

  * Imagen basada en **Debian bookworm** (penúltima versión estable).
  * Instala únicamente los paquetes necesarios:
    * `php-fpm` para ejecutar PHP.
    * Extensiones PHP requeridas por WordPress (mysqli, curl, gd, xml, zip, etc.).
    * `wp-cli` para la instalación y configuración automática de WordPress.
    * Cliente de MariaDB para comprobar la conexión a la base de datos.
  * Crea los directorios necesarios (`/var/www/html`, `/run/php`) y asigna permisos correctos.
  * Copia los archivos de configuración personalizados de PHP y PHP-FPM.
  * Define un `ENTRYPOINT` que automatiza completamente la instalación de WordPress.

* **php.ini**

  * Configuración personalizada de PHP.
  * Ajusta límites importantes para WordPress:
    * Tamaño máximo de subida de archivos.
    * Memoria máxima por script.
    * Tiempo máximo de ejecución.
  * Mejora la compatibilidad y estabilidad del sitio WordPress.
  * Desactiva opciones innecesarias para mejorar la seguridad.

* **www.conf**

  * Archivo de configuración del pool de PHP-FPM.
  * Define:
    * Usuario y grupo (`www-data`).
    * Puerto de escucha **9000** para conexiones FastCGI desde NGINX.
    * Gestión dinámica de procesos PHP según carga.
  * Redirige la salida de errores a logs visibles desde `docker logs`.

* **wordpress_entrypoint.sh**

  * Script ejecutado al iniciar el contenedor.
  * Funciones principales:
    * Esperar a que MariaDB esté disponible antes de continuar.
    * Descargar WordPress automáticamente usando WP-CLI.
    * Crear el archivo `wp-config.php` con las credenciales correctas.
    * Instalar WordPress de forma automática (sin interacción manual).
    * Crear el usuario administrador y un usuario adicional.
    * Ajustar permisos de archivos y directorios.
    * Instalar y configurar Redis Object Cache (bonus).
    * Ejecutar PHP-FPM en primer plano como proceso principal (PID 1).
  * Detecta si WordPress ya está instalado y evita reinstalaciones en reinicios.

### Persistencia de datos

Los archivos de WordPress se almacenan en un **volumen Docker** montado en el host:


Esto incluye:
- Archivos del core de WordPress.
- Temas y plugins.
- Contenido subido por los usuarios (`wp-content/uploads`).

Gracias a este volumen:
- Los datos no se pierden al reiniciar contenedores.
- WordPress se reinstala solo si el volumen está vacío.

### Comunicación con otros servicios

- **MariaDB**
  * WordPress se conecta usando el hostname del servicio (`mariadb`).
  * Las credenciales se leen desde **Docker secrets**.

- **NGINX**
  * Se conecta a PHP-FPM mediante FastCGI en el puerto 9000.
  * NGINX es el único contenedor expuesto al exterior.

- **Redis (Bonus)**
  * Utilizado para cacheo de objetos y mejora del rendimiento.
  * Configurado automáticamente mediante WP-CLI.

### Seguridad

- No se incluyen contraseñas en Dockerfile ni en `docker-compose.yml`.
- Todas las credenciales se leen desde `/run/secrets`.
- WordPress no expone ningún puerto al exterior.
- El acceso externo se realiza únicamente a través de NGINX.

---

Para entender como funciona de forma sencilla

Paso a paso funcionaria así:

  * El usuario escribe la dirección   -> https://login.42.fr
  * NGINX recibe la visita (es la puerta)
  * WordPress decide qué mostrar
  * MariaDB guarda textos, usuarios, contraseñas
  * Se devuelve una página al usuario

Todo eso NO es una sola cosa, son servicios diferentes.

---


## Bonus

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

```bash
 << make up >>
```

make up     # Arrancar proyecto
make down   # Detener contenedores
make re     # Reinicio completo

```

---
