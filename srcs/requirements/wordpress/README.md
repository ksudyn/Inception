# WordPress + PHP-FPM (Parte Obligatoria)

Este contenedor proporciona el **backend PHP** de WordPress para Inception.  
Se ejecuta **en su propio contenedor**, aislado de NGINX y MariaDB, siguiendo estrictamente el subject de Inception.

WordPress no se ejecuta como root y mantiene los datos persistentes en un volumen dedicado.  

Wordpress se encarga de ejecutar **WordPress**, que es una aplicación escrita en **PHP**.

No recibe tráfico directamente desde Internet: solo se comunica con **NGINX** y **MariaDB** dentro de la red interna de Docker
y lo hace usando **Docker secrets** para la configuración segura de contraseñas.

---

## ¿Por qué WordPress necesita su propio contenedor?

WordPress no es un servidor web por sí mismo.  
Para funcionar necesita:

- Un servidor web       -> **NGINX**
- Un intérprete de PHP  -> **PHP-FPM**
- Una base de datos     -> **MariaDB**

En Inception, cada uno de estos componentes debe ejecutarse en **un contenedor independiente**.

---

## Objetivo del servicio WordPress en Inception

* Ejecutar WordPress usando **PHP-FPM**
* No exponer ningún puerto al exterior
* Comunicarse solo con:
  * NGINX (FastCGI)
  * MariaDB (base de datos)
* Usar **Docker secrets** para credenciales
* Mantener los datos persistentes
* Inicializar WordPress solo la primera vez

---

## Estructura del servicio WordPress

```text
srcs/requirements/wordpress/
├── Dockerfile                    <- Imagen del contenedor WordPress/PHP-FPM
├── conf/
│   ├── php.ini                   <- Configuración personalizada de PHP
│   └── www.conf                  <- Configuración del pool PHP-FPM
└── tools/
    └── wordpress_entrypoint.sh   <- Script de arranque e inicialización
```


---

## Dockerfile

- Usa Debian Bullseye
- Instala PHP-FPM y extensiones necesarias
- Instala WP-CLI
- Copia configuraciones personalizadas
- Arranca PHP-FPM en primer plano

WordPress se ejecuta como `www-data`, no como root.

---

## php.ini

Configura el comportamiento del lenguaje PHP.

Incluye:
- Límites de memoria y subida:
  * upload_max_filesize = 64M
  * post_max_size = 64M
  * memory_limit = 256M
  * max_execution_time = 300
  * max_input_vars = 1000
- Configuración de errores
  * display_errors = Off (no mostrar errores al usuario)
  * log_errors = On (guardar errores en /var/log/php_errors.log)
- Medidas de seguridad
  * cgi.fix_pathinfo = 0 (evita ataques de path traversal)
  * expose_php = Off (no mostrar versión de PHP)
- Zona horaria
  * date.timezone = Europe/Madrid

Diseñado específicamente para WordPress.

---

## www.conf (PHP-FPM)

Define cómo PHP-FPM gestiona procesos PHP.

- Escucha en el puerto 9000
- Usuario y grupo
  * www-data
- Permite conexión desde NGINX
  * 0.0.0.0:9000
- Usa gestión dinámica de procesos
  * pm = dynamic
  * pm.max_children = 5
  * pm.start_servers = 2
  * pm.min_spare_servers = 1
  * pm.max_spare_servers = 3
- Redirige logs a Docker
  * catch_workers_output = yes

---

## wordpress_entrypoint.sh

Script ejecutado al iniciar el contenedor.

### Funciones principales

1. Leer contraseñas desde Docker secrets
    * ${WPDB_USER_PASSWORD_FILE}
    * ${WPDB_ROOT_PASSWORD_FILE}
    * ${WP_ADMIN_PASSWORD_FILE}
2. Esperar a que MariaDB esté disponible
    * Host: mariadb
    * Puerto: 3306
    * Usuario: ${WPDB_USER}
3. Descargar WordPress (solo si no existe)
4. Crear wp-config.php automáticamente
5. Instalar WordPress sin interacción
6. Crear usuarios
7. Ajustar permisos
    * Propietario: www-data
    * Permisos 755 para directorios
    * Carpeta wp-content/uploads con permisos 775 (para futura subida de archivos / FTP)
8. Arrancar PHP-FPM en primer plano
    * exec php-fpm7.4 -F

### Persistencia

Si el volumen ya contiene WordPress:
- No se reinstala
- No se sobrescriben datos

---

## Comunicación entre servicios

### Con MariaDB
- Host: mariadb
- Puerto: 3306
- Credenciales vía Docker secrets

### Con NGINX
- Protocolo: FastCGI
- Puerto: 9000
- WordPress no expone puertos
- Host: wordpress
- PHP no se ejecuta en NGINX

---

## Persistencia de datos

- Directorio: `/var/www/html`
- Compartido con NGINX mediante volumen
- Incluye:
  - Core de WordPress
  - Plugins
  - Temas
  - Subidas de usuarios
- Datos sobreviven a reinicios y rebuilds

---

## Seguridad

- No hay credenciales en el código
- WordPress no es accesible directamente
- PHP no muestra errores al usuario
- Uso exclusivo de HTTPS vía NGINX
- PHP-FPM corre como www-data

---

## Preparado para Bonus

🟡 **Relacionado con bonus FTP**
- Permisos de escritura en `wp-content/uploads`
- Facilita subida de archivos vía FTP

(No rompe la parte obligatoria)

---

## Resumen para defensa

- WordPress corre en su propio contenedor
- PHP-FPM ejecuta PHP
- NGINX maneja HTTPS
- MariaDB almacena datos
- Docker secrets para seguridad
- Datos persistentes
- PHP-FPM separado de NGINX  
- Instalación automática

---

