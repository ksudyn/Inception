#!/bin/bash
set -e # hace que el script termine si cualquier comando devuelve un error

# aseguro que los directorios existen y tienen los permisos correctos.
# En principio se crean solos pero de esta forma incluso si alguien borra /var/lib/mysql
# o se monta un volumen vacío, MariaDB podrá escribir sin errores. Buena práctica.
# 	-p -> crea los directorios padres si no existen
# 	/var/lib/mysql -> directorio donde se almacenan los datos de mariadb
# 	/run/mysqld -> directorio donde se almacenan los archivos de socket y PID de mariadb
# chown -R mysql:mysql -> cambia el propietario y grupo del directorio a mysql
# 	-R -> recursivo
# 	mysql:mysql -> propietario y grupo
mkdir -p /var/lib/mysql /run/mysqld && \
chown -R mysql:mysql /var/lib/mysql /run/mysqld
chmod 755 /var/lib/mysql /run/mysqld

#verificación de si la base de datos ya ha sido inicializada
# Si no existe el directorio /var/lib/mysql/mysql, significa que la base de datos
# no ha sido inicializada, por lo que procedemos a inicializarla.
# Si ya existe, significa que la base de datos ya ha sido inicializada,
# por lo que no hacemos nada.
# Esto evita que se sobrescriban los datos cada vez que se reinicia el contenedor
# o se monta un volumen con datos ya existentes.
# mysql_install_db -> comando que inicializa la base de datos MariaDB
# --user=mysql -> ejecuta el comando como el usuario mysql
# --datadir=/var/lib/mysql -> especifica el directorio donde se almacenan los datos
# --auth-root-authentication-method=normal -> establece el método de autenticación
# 	para el usuario root como "normal", lo que permite usar una contraseña en lugar
# 	de métodos más seguros como socket o PAM.
if [ ! -d "/var/lib/mysql/mysql" ]; then
	echo "[+] Base de datos no encontrada, inicializando..."
	mysql_install_db --user=mysql --datadir=/var/lib/mysql --auth-root-authentication-method=normal
	echo "[+] Base de datos MariaDB inicializada."
else
	echo "[+] Base de datos ya inicializada, saltando inicialización."
fi

if [ -f /var/lib/mysql/.mysql_initialized ]; then
	echo "[+] La DB de WordPress ya ha sido configurada previamente, saltando configuración."
	echo "[+] Arrancando MariaDB normalmente..."
	exec mysqld
fi

# arrancar MariaDB en segundo plano para poder configurar la base de datos
# de wordpress (crear base de datos y usuarios) Esta parte no se ejecutará
# en futuros reinicios del contenedor porque se crea el archivo
# /var/lib/mysql/.mysql_initialized al final del script (Como un flag).
# & -> ejecuta el comando en segundo plano para que el script continúe.
echo "[+] Arrancando servidor temporal para configuración inicial..."
mysqld &

# esperar a que MariaDB esté listo
until mysqladmin ping ; do
	echo "Esperando a que MariaDB esté disponible..."
	sleep 1
done

DB_NAME=${WP_DATABASE}
DB_USER=${WPDB_USER}
DB_ROOT=${WPDB_ROOT_USER}

DB_USER_PASS=$(cat "${WPDB_USER_PASSWORD_FILE}")
DB_ROOT_PASS=$(cat "${WPDB_ROOT_PASSWORD_FILE}")
MDB_ROOT_PASS=$(cat "${MDB_ROOT_PASSWORD_FILE}")

echo "[+] Creando base de datos y usuarios..."

# Crear la base de datos y los usuarios con los privilegios adecuados
# Uso comillas invertidas (`) para el nombre de la base de datos en caso de
# que contenga caracteres especiales o sea una palabra reservada.
# Uso comillas simples (') para los nombres de usuario y contraseñas.
# 	'%' -> permite conexiones desde cualquier host
# ALTER USER -> Cambiamos la contraseña del root de Debian, no del usuario WordPress
# FLUSH PRIVILEGES; -> recarga los privilegios para que los cambios tengan efecto
# <<-EOSQL ... EOSQL -> permite ejecutar múltiples comandos SQL en un solo bloque (HEREDOC).
mysql -u root <<-EOSQL
	CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
	CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_USER_PASS}';
	GRANT SELECT, INSERT, UPDATE, DELETE ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
	CREATE USER IF NOT EXISTS '${DB_ROOT}'@'%' IDENTIFIED BY '${DB_ROOT_PASS}';
	GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_ROOT}'@'%';
	ALTER USER 'root'@'localhost' IDENTIFIED BY '${MDB_ROOT_PASS}';
	FLUSH PRIVILEGES;
EOSQL

echo "[+] Deteniendo servidor temporal..."
mysqladmin -uroot -p"${MDB_ROOT_PASS}" shutdown
touch /var/lib/mysql/.mysql_initialized

echo "[+] Arrancando MariaDB normalmente..."
exec mysqld
