# Usamos Debian bookworm (penúltima versión estable)
FROM debian:bookworm

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

# Definimos el entrypoint para inicializar nginx al arrancar el contenedor.
# Basicamente cuando el contenedor arranque, ejecuta esto.
ENTRYPOINT ["/usr/local/bin/nginx_entrypoint.sh"]

HEALTHCHECK --interval=10s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -k -f https://localhost/healthz || exit 1

# --interval=10s      -> Cada 10 segundos, Docker ejecuta el healthcheck
# --timeout=5s        -> Si el comando tarda más de 5 segundos, se considera fallido.
# --start-period=20s  -> Durante los primeros 20 segundos, Docker no penaliza errores.
# --retries=3         -> Si falla 3 veces seguidas, Docker marca el contenedor como STATUS: unhealthy

# curl                        -> Herramienta para hacer peticiones HTTP/HTTPS.
# -k                          -> No compruebes si el certificado es válido.
# -f                          -> Si el servidor responde con error HTTP, curl falla.
# https://localhost/healthz   -> Esto llama a este bloque:
#                                 location = /healthz {
#                                     return 200 "ok\n";
#                                 }
# || exit 1                   -> Si curl falla sale con erro (unhealthy)

# Define la imagen base y los paquetes necesarios.
# Copia configuraciones y scripts.
# Da permisos de ejecución a los scripts.
# Expone solo el puerto 443 para HTTPS.
# Usa un ENTRYPOINT que asegura que los certificados se generen y NGINX se inicie correctamente.

# “El HEALTHCHECK permite a Docker verificar periódicamente que NGINX sigue funcionando correctamente por HTTPS.
# Se comprueba una ruta ligera (/healthz) sin depender de WordPress ni de la base de datos,
# y se ignora el certificado autofirmado. Si falla varias veces seguidas,
# Docker marca el contenedor como no saludable.”