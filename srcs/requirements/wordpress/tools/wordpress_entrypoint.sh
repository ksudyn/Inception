#!/bin/bash
set -e  # Detener el script si ocurre cualquier error

# ----------------------------------------------------
# Leer contraseñas desde Docker secrets
# ----------------------------------------------------
WPDB_USER_PASS=$(cat "${WPDB_USER_PASSWORD_FILE}")
WPDB_ROOT_PASS=$(cat "${WPDB_ROOT_PASSWORD_FILE}")
WP_ADMIN_PASS=$(cat "${WP_ADMIN_PASSWORD_FILE}")

# ----------------------------------------------------
# Esperar a que MariaDB esté disponible
# ----------------------------------------------------
wait_for_db() {
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
	# Ajustar permisos
	chown -R www-data:www-data /var/www/html
	chmod -R 755 /var/www/html

	echo "[+] WordPress instalado correctamente."
else
	echo "[+] WordPress ya instalado. Saltando instalación."
fi

# ----------------------------------------------------
# Arrancar PHP-FPM en primer plano
# ----------------------------------------------------
exec php-fpm7.4 -F
