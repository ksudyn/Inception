## NGINX (Parte Obligatoria)

Servicio encargado de actuar como **servidor web** y **reverse proxy** del proyecto.  
Es el **único contenedor expuesto al exterior**.

NGINX se encarga de:  
- Gestionar conexiones **HTTPS**.  
- Servir contenido estático.  
- Redirigir peticiones PHP a WordPress mediante **FastCGI**.  
- Aplicar configuración de seguridad TLS.

---

## Objetivo del servicio NGINX en Inception

* Servir contenido web y redirigir peticiones a WordPress.  
* Aplicar **HTTPS obligatorio** con certificados gestionados en el contenedor.  
* Gestionar el tráfico hacia WordPress usando **FastCGI** (PHP-FPM).  
* Mantener un entorno seguro y escalable, aislado del resto de servicios.  
* Evitar que NGINX se ejecute como root o exponga información sensible.  

---

## Estructura del servicio NGINX

```text

srcs/requirements/nginx/
├── README.md                       <- Este README
├── Dockerfile                      <- Imagen del contenedor NGINX
├── conf/
│ ├── nginx.conf                    <- Configuración global de NGINX
│ └── default.conf.template         <- Configuración de virtual host
└── tools/
├── generate_certs.sh               <- Genera certificados SSL/TLS
└── nginx_entrypoint.sh             <- Script de arranque del contenedor

```


---

## Componentes

* **Dockerfile**

  * Imagen basada en **Debian Bullseye** (penúltima versión estable).
  * No usar imágenes oficiales de NGINX.
  * Instalar solo paquetes necesarios para servidor web y TLS:
    * `nginx`  
    * `openssl` 
  * Copia archivos de configuración personalizados.  
  * Copia el script de generación de certificados.  
  * Usa un `ENTRYPOINT` para inicializar certificados y arrancar NGINX.  
  * Ejecuta NGINX en primer plano (`daemon off;`) como proceso principal.

* **default.conf.template**

  * Archivo de configuración del virtual host de NGINX para WordPress.
  * Este archivo define **cómo debe responder NGINX a cada tipo de petición HTTP/HTTPS** que recibe desde el exterior.
  * Utiliza variables de entorno (ej. `DOMAIN_NAME`) que se sustituyen en tiempo de ejecución.
  * Permitiendo que la misma imagen sea reutilizable en distintos entornos sin modificar el código
  * Define:
    * Puerto **443** con HTTPS.  
    * Certificados TLS, desde Docker secrets, evitando incluir claves privadas en el repositorio.
    * Redirección de peticiones PHP hacia WordPress.
    * Configura el uso obligatorio de **TLS v1.2 y TLS v1.3**.
  * Ejemplo de responsabilidades:
    * `root /var/www/html;`
      Indica el directorio desde el que NGINX sirve los archivos web.
    * `index index.php index.html;`
      Define los archivos por defecto cuando se accede a un directorio.
    * `location / { ... }`  
    Gestiona el enrutamiento principal de WordPress, redirigiendo las peticiones al
    archivo `index.php` cuando el recurso solicitado no existe directamente.  
    Este comportamiento es esencial para el funcionamiento interno de WordPress.

  * `location ~ \.php$ { ... }`  
    Redirige todas las peticiones a archivos PHP hacia el contenedor de WordPress
    mediante **FastCGI**, utilizando PHP-FPM como motor de ejecución.
    NGINX **no ejecuta PHP directamente**, cumpliendo la separación de responsabilidades.

  * `location ~* \.(jpg|css|js|...)$ { ... }`  
    Optimiza la entrega de archivos estáticos (imágenes, CSS, JavaScript), permitiendo
    que el navegador los cachee y mejorando el rendimiento general del sitio.

  * `location ~ /\. { deny all; }`  
    Bloquea el acceso a archivos ocultos o sensibles (como `.env`, `.git`, etc.),
    aumentando la seguridad del servidor. 

* **nginx.conf**

  * Configuración global de NGINX, controla el comportamiento general del servidor.
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

---

## Configuración HTTPS (TLS)

- NGINX usa **TLSv1.2 y TLSv1.3**.  
- El puerto **443** es el único expuesto al exterior.  
- Certificados cargados desde Docker secrets:
  - `/run/secrets/nginx.crt`  
  - `/run/secrets/nginx.key`  
- El tráfico HTTP sin cifrar **no está permitido**.

---

## Comunicación con WordPress

NGINX se comunica con WordPress mediante **FastCGI**:

- Host: `wordpress`  
- Puerto: `9000`  
- Protocolo: FastCGI  
- No ejecuta PHP directamente.

Esto permite:  
- Separación clara de responsabilidades.  
- Mayor seguridad.  
- Escalabilidad futura.

---

## Volúmenes

- Comparte el volumen `wordpress_data`  
- Permite servir:
  - Archivos PHP  
  - Recursos estáticos (CSS, JS, imágenes)  

---

## Seguridad

- NGINX es el único punto de entrada externo.  
- No se ejecuta como root.  
- No expone información de versiones.  
- Bloquea acceso a archivos ocultos y sensibles.  
- Uso exclusivo de HTTPS.

---

## Resumen para defensa

* NGINX corre en su propio contenedor.  
* Usa Debian Bullseye.  
* No hay contraseñas en el código.  
* Solo expone el puerto 443.  
* Gestiona certificados mediante Docker secrets.  
* Redirige PHP a WordPress mediante FastCGI.  

✔ Cumple completamente el subject de Inception
