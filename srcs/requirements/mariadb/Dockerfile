# Usamos Debian Bullseye (penúltima versión estable)
FROM debian:bullseye

# Evitamos preguntas interactivas durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# Instalamos MariaDB server sin paquetes innecesarios
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends mariadb-server && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copiamos la configuración personalizada
COPY conf/my.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Copiamos el script de inicialización y le damos permisos de ejecución
COPY tools/mariadb_entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mariadb_entrypoint.sh

# Exponemos el puerto estándar de MariaDB
EXPOSE 3306

# Definimos el entrypoint para inicializar MariaDB al arrancar el contenedor
ENTRYPOINT ["/usr/local/bin/mariadb_entrypoint.sh"]
