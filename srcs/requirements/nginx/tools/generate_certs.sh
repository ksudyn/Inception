#!/bin/bash
set -e

# Ruta donde se guardarán los certificados
CERT_PATH=/run/secrets

# Dominio, por defecto localhost
DOMAIN=${DOMAIN_NAME:-localhost}

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