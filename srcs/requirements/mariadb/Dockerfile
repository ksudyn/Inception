# Usamos Debian Bullseye (penúltima versión estable), nO es un contenedor, es una imagen base.
FROM debian:bullseye
# Se usa Debian y no Alpine porque Alpine es más complicado con MariaDB
# y Debian es más estable y claro.

# Evitamos preguntas interactivas durante la instalación.
ENV DEBIAN_FRONTEND=noninteractive

# Instalamos MariaDB server sin paquetes innecesarios.
# Descarga la lista de programas disponibles.
# apt-get update -y                 -> Descarga la lista de programas disponibles.
# apt-get install -y mariadb-server -> Instala MariaDB.
# --no-install-recommends           -> Instala SOLO lo necesario, nada extra.
# apt-get clean                     -> Borra archivos temporales de instalación.
# rm -rf /var/lib/apt/lists/*       -> Borra listas descargadas de programas.
# -y                                -> Significa sí a todo.
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends mariadb-server && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copiamos la configuración personalizada.
# Copia un archivo desde tu proyecto al contenedor.
# Tiene esta ruta porque MariaDB lee automáticamente esa carpeta.
COPY conf/my.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Copia tu script de inicializacion para poder usarlo.
COPY tools/mariadb_entrypoint.sh /usr/local/bin/
# Da permiso para ejecutar el archivo.
RUN chmod +x /usr/local/bin/mariadb_entrypoint.sh

# Exponemos el puerto estándar de MariaDB
EXPOSE 3306

# Definimos el entrypoint para inicializar MariaDB al arrancar el contenedor.
# Basicamente cuando el contenedor arranque, ejecuta esto.
ENTRYPOINT ["/usr/local/bin/mariadb_entrypoint.sh"]
