#!/bin/bash
# #!/bin/bash le dice al contenedor que use bash para ejecutar el script.
# Aunque empieza con #, esta línea NO es un comentario normal.

set -e
# Hace que el script se detenga inmediatamente si ocurre cualquier error.
# En Docker es importante fallar rápido para no dejar instalaciones a medias
# o contenedores en estados incoherentes.


# Docker secrets monta las contraseñas como archivos.
# Aquí leemos el contenido de esos archivos y lo guardamos en variables usando cat.
# Esto evita escribir contraseñas directamente en el código (buena práctica).
# y esto lo hace Docker porque monta los secrets como archivos, no como texto visible
WPDB_USER_PASS=$(cat "${WPDB_USER_PASSWORD_FILE}")
# Contraseña del usuario normal de WordPress para la base de datos.

WPDB_ROOT_PASS=$(cat "${WPDB_ROOT_PASSWORD_FILE}")
# Contraseña del usuario root lógico de WordPress (no es el root del sistema).

WP_ADMIN_PASS=$(cat "${WP_ADMIN_PASSWORD_FILE}")
# Contraseña del usuario administrador de WordPress.



# wait_for_db es solo el nombre de una función que contiene ese bucle
# dentro until es como un bucle que dice que haz esto hata que funciones, en este caso hasta que de ok
# y mysqladmin ping verifica si MariaDB esta lista para conectarse, de ahí el until, aqui entra el ok
# sirve para decirle a WordPress no empieces todavía, empieza solo cuando la base de datos esté lista
# basicamente cuando Maria DB esré lista

# Luego busca a MariaDB y usa el usuario y su contraseña para conectarse
# y si son correctas todo da bien y se sigue.
# --silent hace qie no se escriban mensajes innecesarios
# Si no el do escribe su respectivo mensaje y espera un segundo para volver a intentar todo

# -h indica el host donde está MariaDB (otro contenedor dentro de la red Docker)
# sin -h buscaría la base de datos dentro del contenedor de WordPress (localhost)
# -u indica el usuario con el que WordPress se conecta a la base de datos
# es un usuario de MariaDB, no del sistema Linux
# -p indica la contraseña de ese usuario
# si el usuario o la contraseña no son correctos, la conexión falla
wait_for_db()
{
	until mysqladmin ping \
		-h "$DB_HOSTNAME" \
		-u "$WPDB_USER" \
		-p"$WPDB_USER_PASS" \
		--silent; do
		echo "Esperando a MariaDB..."
		sleep 1
	done
	echo "[+] MariaDB lista."
}

# Llama a la funció y espera a que MariaDB esté lista antes de que WordPress intente conectarse a la base de datos.
wait_for_db

# Esto " ! -f" verifica si el archivo wp-config.php ya existe
# Si no existe entra y lo empieza a instalar creando wp-config.php
if [ ! -f /var/www/html/wp-config.php ]; then
	echo "[+] Instalando WordPress..."
# wp es un programa de línea de comandos para WordPress
	wp core download --allow-root --path=/var/www/html

	# Pero para crear la base de datos de wordpress necesitamos el usuario root
	echo "[+] Creando wp-config.php..."
	wp config create --allow-root \
		--dbname="$WP_DATABASE" \
		--dbuser="$WPDB_USER" \
		--dbpass="$WPDB_USER_PASS" \
		--dbhost="$DB_HOSTNAME" \
		--path=/var/www/html

	echo "[+] Instalando WordPress..."
	wp core install --allow-root \
		--url="https://${DOMAIN_NAME}" \
		--title="Inception WordPress" \
		--admin_user="$WP_ADMIN_USER" \
		--admin_password="$WP_ADMIN_PASS" \
		--admin_email="$WP_ADMIN_EMAIL" \
		--path=/var/www/html

	# --- Crear usuario adicional ---
	if [ ! -z "$WP_USER" ]; then
		echo "[+] Creando usuario secundario..."
		wp user create "$WP_USER" "$WP_USER_EMAIL" \
			--user_pass="$WP_USER_PASS" \
			--role=subscriber \
			--allow-root
	fi

	# --- Ajustar permisos para directorios y archivos de la instalación de WordPress ---
	# En uploads permito escritura al grupo porque ahí es donde el FTP subirá archivos
	chown -R www-data:www-data /var/www/html
	chmod -R 755 /var/www/html
	chmod -R 775 "/var/www/html/wp-content/uploads"

	# --- Arrancar PHP-FPM en primer plano ---
	echo "[+] Arrancando PHP-FPM..."
	exec php-fpm7.4 -F
fi
echo "[+] WordPress ya instalado. Saltando instalación..."
exec php-fpm7.4 -F  # Arranca PHP-FPM en primer plano
