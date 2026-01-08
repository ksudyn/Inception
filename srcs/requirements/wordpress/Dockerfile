# Penúltima versión estable de Debian
FROM debian:bullseye

# Evitar preguntas interactivas
ENV DEBIAN_FRONTEND=noninteractive


# Instalación de wordpress con PHP-fpm (todo en un solo RUN para reducir el número de capas)
# -y                            -> responde "si" a todas las preguntas que haga apt-get
# --no-install-recommends       -> instala solo lo necesario, sin paquetes adicionales
# de configuración.
# apt-get clean &&              -> limpia la cache de apt-get para reducir el tamaño de la imagen
# rm -rf /var/lib/apt/lists/*   -> elimina los indices descargados por apt-get update
# Instalado:
# 	php7.4-fpm          -> PHP FastCGI Process Manager, para ejecutar PHP con Nginx
#	php7.4-cli          -> Interfaz de línea de comandos de PHP (necesario para wp-cli)
#	php7.4-mysqli       -> extensión para conectar PHP con bases de datos MySQL/MariaDB
#	php7.4-curl         -> Extensión PHP usada por WordPress para actualizaciones, plugins y APIs.
#	php7.4-gd           -> Manipula imágenes (WordPress lo usa al subir fotos).
#	php7.4-mbstring     -> Soporte para caracteres multibyte (acentos, UTF-8, emojis).
#	php7.4-xml          -> Necesario para feeds RSS, exportaciones/importaciones y algunos plugins.
#	php7.4-zip          -> Para descomprimir temas/plugins en formato ZIP.
#	ca-certificates     -> Permite conexiones HTTPS seguras (sin esto wget o curl podrían fallar).
#	wget                -> Descarga archivos desde Internet (wget https://wordpress.org/latest.tar.gz).
#	unzip               -> Descomprime el archivo ZIP, por ejemplo el paquete de instalacion de wordpress.
#	mariadb-client      -> Permite probar conexión a la base de datos desde el contenedor.
# Instalar PHP-FPM y dependencias necesarias para WordPress
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        php7.4-fpm \
        php7.4-cli \
        php7.4-mysqli \
        php7.4-curl \
        php7.4-gd \
        php7.4-mbstring \
        php7.4-xml \
        php7.4-zip \
        ca-certificates \
        wget unzip mariadb-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Instalar wp-cli en la imagen. Herramienta de línea de comandos para gestionar instalaciones de WordPress.
# -q        -> modo silencioso (no muestra salida)
# -O        -> guarda el archivo con el nombre especificado
# chmod +x  -> da permisos de ejecución al archivo descargado
RUN wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    -O /usr/local/bin/wp && chmod +x /usr/local/bin/wp

# Crear directorio de WordPress y ajustar permisos. útil sólo si no se monta volumen del host
# Lo dejo para que la imagen valga tanto si se monta volumen como si no.
RUN mkdir -p /var/www/html /run/php && \
    chown -R www-data:www-data /var/www/html /run/php && \
    chmod -R 755 /var/www/html

# Copiar archivos de configuración personalizados (opcional)
# php.ini   -> configuración general de PHP. (personalización de límites)
#			se copia en dos ubicaciones para asegurar que tanto PHP-FPM como la CLI usen la misma configuración.
# www.conf  -> configuración específica de PHP-FPM (usuario, grupo, puerto de escucha).
COPY conf/php.ini /etc/php/7.4/fpm/conf.d/custom.ini
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

# Copiar el script de entrada y dar permisos de ejecución
COPY tools/wordpress_entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wordpress_entrypoint.sh


# Sólo informativa (el contenedor de mariadb escucha en el puerto 3306)
EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/wordpress_entrypoint.sh"]
