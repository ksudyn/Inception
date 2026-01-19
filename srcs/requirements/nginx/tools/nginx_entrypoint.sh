#!/bin/bash
set -e

# Generar certificados si no existen
/tools/generate_certs.sh

# Sustituir variables de entorno en el template

# “El proyecto se copia dentro del contenedor siguiendo la estructura estándar de Linux.
# Aunque el archivo esté en srcs/requirements/nginx en el host, dentro del contenedor vive en /etc/nginx,
# que es donde NGINX espera su configuración.”
# En linux etc es la configuracion del sistema.

# El .d le dice que dentro de conf busque los direcitorios, asi que conf.d significa (directorios de configuracion)

# Aqui se coge la variable de entorno DOMAIN_NAME con su valor real (login.42.fr)
# Va al archivo default.conf.template
# Donde aparece ${DOMAIN_NAME}, lo sustituye por login.42.fr
# Porque NGINX no entiende variables de entorno, solo texto
# Crea un archivo nuevo llamado default.conf
# NGINX usa ese archivo nuevo, no el template
envsubst '\$DOMAIN_NAME' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf


# Arranca NGINX como proceso principal del contenedor
# nginx                 -> Arranca el servidor web NGINX
# -g                    -> Permite pasar una configuración directamente por línea de comandos
# 'daemon off;'         -> Evita que NGINX se vaya a segundo plano
#                           En Docker, si el proceso principal termina, el contenedor se detiene
#                           Por eso NGINX debe quedarse en primer plano
nginx -g 'daemon off;'

