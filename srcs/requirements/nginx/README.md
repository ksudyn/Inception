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
