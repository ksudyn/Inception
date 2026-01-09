#!/bin/bash
set -e  # Detener el script si ocurre cualquier error, evita instalaciones a medias.

# ----------------------------------------------------
# Leer contraseñas desde Docker secrets
# ----------------------------------------------------
WPDB_USER_PASS=$(cat "${WPDB_USER_PASSWORD_FILE}")
WPDB_ROOT_PASS=$(cat "${WPDB_ROOT_PASSWORD_FILE}")
WP_ADMIN_PASS=$(cat "${WP_ADMIN_PASSWORD_FILE}")

# ----------------------------------------------------
# Esperar a que MariaDB esté disponible
# ----------------------------------------------------
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

# Espera a que MariaDB esté lista antes de que WordPress intente conectarse a la base de datos.
wait_for_db

# ----------------------------------------------------
# Instalación de WordPress (solo primera vez)
# ----------------------------------------------------
if [ ! -f /var/www/html/wp-config.php ]; then
	echo "[+] Instalando WordPress..."

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
