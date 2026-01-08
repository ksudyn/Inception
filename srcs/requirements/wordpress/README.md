# WordPress + PHP-FPM (Parte Obligatoria)

Este contenedor proporciona el **backend PHP** de WordPress para Inception.  
Se ejecuta **en su propio contenedor**, aislado de NGINX y MariaDB, siguiendo estrictamente el subject de Inception.

WordPress no se ejecuta como root y mantiene los datos persistentes en un volumen dedicado.  
El contenedor se comunica con MariaDB usando **Docker secrets** para la configuración segura de contraseñas.

---

## Objetivo del servicio WordPress

* Ejecutar WordPress mediante **PHP-FPM** (FastCGI Process Manager).  
* Inicializar WordPress **solo la primera vez** que se arranca el contenedor.  
* Conectarse a MariaDB usando contraseñas **sin hardcodearlas** (Docker secrets).  
* Mantener los datos persistentes en `/var/www/html`.  
* Permitir que NGINX actúe como **reverse proxy** y gestione HTTPS.  
* Usar buenas prácticas de seguridad y configuración PHP para WordPress.  
* Incluir herramientas de administración opcionales (wp-cli) para automatización.

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

## Comunicación con NGINX

- Protocolo: FastCGI
- Host: wordpress
- Puerto: 9000
- PHP no se ejecuta en NGINX

---

## Persistencia

- /var/www/html montado como volumen
- Datos sobreviven a reinicios y rebuilds

---

## Seguridad

- Uso de Docker secrets
- PHP no expone versión
- PHP-FPM corre como www-data

---

## Resumen para defensa

✔ Contenedor independiente  
✔ PHP-FPM separado de NGINX  
✔ Instalación automática  
✔ Datos persistentes  
✔ Cumple subject Inception
