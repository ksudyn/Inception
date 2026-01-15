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
# Es una herramienta oficial de WordPress para controlarlo desde la terminal
	wp core download --allow-root --path=/var/www/html
# core es el nucleo de WordPress, dowland le dice que descargue WordPress.
# --alow-root significa que se ejecute este comando como el usuario root asi puede hacer cualquier cosa sin restricciones
# y --path=/var/www/html es donde se va a descaragra WordPress por que es el diretorio estandae de servidores web

# confi create crea el archivo wp-config.php
# con --allow-root se permite ejecutar el comando como usuario root que es necesario en Docker
# --dbname es el nombre de la base de datos y WP_DATABASE debe coincidir con lo que se creo en MariaDB
# --dbuser es el usuario de la base de datos ( NO root del sistema)
# --dbpass es la contraseña del usuario
# --dbhost es la direccion del servidor de base de datos
# y todo esto se crea en la direccion --path=/var/www/html
	echo "[+] Creando wp-config.php..."
	wp config create --allow-root \
		--dbname="$WP_DATABASE" \
		--dbuser="$WPDB_USER" \
		--dbpass="$WPDB_USER_PASS" \
		--dbhost="$DB_HOSTNAME" \
		--path=/var/www/html


# wp core install realiza la instalación inicial de WordPress
# es equivalente al instalador web que aparece la primera vez
# --allow-root permite ejecutar el comando como root dentro del contenedor
# --url define la URL oficial del sitio, debe coincidir con el dominio configurado en NGINX
# --title es el nombre del sitio web
# --admin_user crea el usuario administrador de WordPress
# el nombre no puede contener "admin" según el subject
# --admin_password define la contraseña del administrador
# --admin_email define el correo del administrador (WordPress lo exige)
# --path indica dónde está instalada la web
	echo "[+] Instalando WordPress..."
	wp core install --allow-root \
		--url="https://${DOMAIN_NAME}" \
		--title="Inception WordPress" \
		--admin_user="$WP_ADMIN_USER" \
		--admin_password="$WP_ADMIN_PASS" \
		--admin_email="$WP_ADMIN_EMAIL" \
		--path=/var/www/html

# if [ ! -z "$WP_USER" ]; then comprueba si la variable WP_USER no está vacía
# -z significa "cadena vacía"
# si no existe un usuario definido, no se crea ningún usuario extra

# wp user create crea un nuevo usuario en WordPress
# "$WP_USER" es el nombre del usuario
# "$WP_USER_EMAIL" es el correo del usuario
# --user_pass define la contraseña del usuario
# --role=subscriber asigna el rol más básico (solo lectura)
# se usa subscriber por seguridad y porque no necesita privilegios
# --allow-root permite ejecutar el comando como root en Docker
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
	# www-data es el usuario con el que corre PHP-FPM.
	chmod -R 755 /var/www/html
	# Permisos estándar: lectura y ejecución.
	chmod -R 775 "/var/www/html/wp-content/uploads"
	# uploads necesita permisos de escritura para subir archivos.

	# --- Arrancar PHP-FPM en primer plano ---
	echo "[+] Arrancando PHP-FPM..."
	exec php-fpm7.4 -F
	# exec reemplaza el proceso actual por PHP-FPM.
	# -F significa que se ejecuta en primer plano.
	# En Docker, el proceso principal NO debe ir en segundo plano.
fi
echo "[+] WordPress ya instalado. Saltando instalación..."
exec php-fpm7.4 -F # Arrancamos PHP-FPM directamente sin reinstalar nada.


# “Todos los comandos wp se usan para automatizar la instalación de WordPress dentro de Docker,
# ya que no se puede usar el instalador web.
# Las opciones como --allow-root y --path son necesarias por la forma en la que Docker ejecuta los contenedores
# y por la estructura estándar de servidores web.”