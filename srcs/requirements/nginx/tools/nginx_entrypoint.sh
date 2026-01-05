#!/bin/bash
set -e

# Generar certificados si no existen
/tools/generate_certs.sh

# Sustituir variables de entorno en el template
envsubst '\$DOMAIN_NAME' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

# Arrancar NGINX en primer plano
nginx -g 'daemon off;'



# Genera certificados si hace falta.
# Reemplaza ${DOMAIN_NAME} en el template por la variable real.
# Inicia NGINX en primer plano (cumple la práctica Docker).