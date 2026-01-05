# Usamos Debian Bullseye (penúltima versión estable)
FROM debian:bullseye

# Evitar preguntas interactivas al instalar paquetes
ENV DEBIAN_FRONTEND=noninteractive

# Instalamos solo lo necesario:
# - nginx        -> servidor web
# - openssl      -> generación de certificados TLS
# - gettext-base -> envsubst (sustituir variables de entorno)
# - curl         -> healthcheck
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        nginx \
        openssl \
        gettext-base \
        curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copiamos configuración
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/default.conf.template /etc/nginx/conf.d/default.conf.template

# Copiamos scripts
COPY tools/generate_certs.sh /usr/local/bin/
COPY tools/nginx_entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# Permisos del directorio web
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# Exponemos solo HTTPS
EXPOSE 443

# Arrancamos siempre mediante el entrypoint
ENTRYPOINT ["/usr/local/bin/nginx_entrypoint.sh"]

HEALTHCHECK --interval=10s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -k -f https://localhost/healthz || exit 1



# Define la imagen base y los paquetes necesarios.
# Copia configuraciones y scripts.
# Da permisos de ejecución a los scripts.
# Expone solo el puerto 443 para HTTPS.
# Usa un ENTRYPOINT que asegura que los certificados se generen y NGINX se inicie correctamente.