#!/bin/bash
# Esto le dice al sistema que use Bash, que esta disponible para Debian.
set -e
# Si ocurre algun error se detiene el script.


# CERT_PATH es una variable donde se guarda la ruta donde se guardarán los certificados
# Se pone esa ruta porque Docker monta secrest automaticamente ahí
CERT_PATH=/run/secrets

# DOMAIN (dominio) es el nombre de tu página web
# En Inception seria login.42.fr
# Si existe DOMAIN_NAME, se usa, si no, se usa loclahost.
DOMAIN=${DOMAIN_NAME:-localhost}

# ! -f        -> significa si no existe este archivo ( -f es archivo y ! es no)
# El resto se refiere a si existe el certificado y su contraseña
# Ese certificado sirve para permitir que tu web funcione con HTTPS (https://)
# y cifrar la comunicación entre el navegador y tu servidor NGINX
# Sin ellos HTTPS no puede arrancar el puerto 443 y NGINX no puede arrancar el puerto 443

# openssl req           -> Crea un certificado SSL
# -x509                 -> Indica que es un certificado autofirmado
# -nodes                -> Significa no cifres la clave privada,
#                           significa que no hace falta dar ninguna contraseña,
#                           si no, te pide una clave que no puedes dar y da error
# -days 365             -> significa que valida esto durante 365 días


# Solo genera certificados si no existen
if [ ! -f "$CERT_PATH/nginx.crt" ] || [ ! -f "$CERT_PATH/nginx.key" ]; then
    echo "[+] Generando certificados SSL/TLS para $DOMAIN..."
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout $CERT_PATH/nginx.key \
        -out $CERT_PATH/nginx.crt \
        -subj "/CN=$DOMAIN"
else
    echo "[+] Certificados ya existen, no se generan de nuevo."
fi


# Genera certificados autofirmados solo si no existen.
# Usa la variable de entorno DOMAIN_NAME.
# Guarda certificados en /run/secrets.