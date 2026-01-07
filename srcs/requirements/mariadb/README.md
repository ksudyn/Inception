## MariaDB (Parte Obligatoria)

Este servicio proporciona la **base de datos** utilizada por WordPress. En Inception, MariaDB debe ejecutarse **en su propio contenedor**, con **datos persistentes**, **sin contraseñas hardcodeadas** y partiendo de una imagen base **Debian (penúltima versión estable)**.

---

## Objetivo del servicio MariaDB en Inception

* Almacenar de forma persistente los datos de WordPress.
* Crear automáticamente:

  * La base de datos de WordPress
  * Un usuario normal para WordPress
  * Un usuario con más privilegios (root lógico)
* Usar **Docker secrets** para las contraseñas.
* Evitar que la base de datos se reinicialice en cada arranque.

---

## Estructura del servicio MariaDB

```
srcs/requirements/mariadb/
├── README.md              <- Tu README detallado
├── Dockerfile             <- Contenedor MariaDB
├── conf/
│   └── my.cnf             <- Configuración personalizada de MariaDB
└── tools/
    └── mariadb_entrypoint.sh  <- Script de inicialización de MariaDB
```

---

## Dockerfile

### ¿Qué es?

El `Dockerfile` define **cómo se construye la imagen** del contenedor MariaDB.

### Requisitos del subject

* Imagen base: **Debian (penúltima versión estable)**
* No usar imágenes oficiales de MariaDB
* Instalar solo lo necesario

### Dockerfile explicado

```dockerfile
FROM debian:bullseye
```

* Usa Debian Bullseye, que es la penúltima versión estable exigida.

```dockerfile
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends mariadb-server && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

* Instala MariaDB Server
* `--no-install-recommends`: evita paquetes innecesarios
* Limpia la caché para reducir el tamaño de la imagen

```dockerfile
COPY conf/my.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
```

* Sobrescribe la configuración por defecto de MariaDB
* Permite ajustes personalizados (charset, bind-address, InnoDB)

```dockerfile
COPY tools/mariadb_entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mariadb_entrypoint.sh
```

* Copia el script de inicialización
* Se le dan permisos de ejecución

```dockerfile
EXPOSE 3306
```

* Puerto estándar de MariaDB (informativo)

```dockerfile
ENTRYPOINT ["/usr/local/bin/mariadb_entrypoint.sh"]
```

* El contenedor arranca siempre ejecutando este script

---

## my.cnf

### ¿Qué es?

Archivo de configuración personalizado de MariaDB.

### Objetivos

* Compatibilidad total con WordPress
* Buen rendimiento en contenedor
* Soporte UTF-8 completo

### Configuración explicada

```ini
[mysqld]
bind-address = 0.0.0.0
```

* Permite conexiones desde otros contenedores (WordPress)

```ini
character-set-server = utf8mb4
collation-server = utf8mb4_general_ci
```

* Soporte completo para emojis y caracteres especiales

```ini
innodb_buffer_pool_size = 128M
innodb_file_per_table = 1
```

* Ajustes InnoDB recomendados para WordPress

```ini
max_connections = 100
```

* Límite razonable para evitar consumo excesivo de RAM

---

## mariadb_entrypoint.sh

### ¿Qué es?

Script que se ejecuta **al arrancar el contenedor**. Controla toda la lógica de inicialización.

### Objetivos del script

* Crear directorios y permisos
* Inicializar MariaDB solo la primera vez
* Crear base de datos y usuarios
* Leer contraseñas desde Docker secrets
* Arrancar MariaDB en primer plano

---

### Paso 1: Seguridad y permisos

```bash
set -e
```

* El script se detiene si ocurre cualquier error

```bash
mkdir -p /var/lib/mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql /run/mysqld
```

* Garantiza que los directorios existen
* Evita errores si el volumen está vacío

---

### Paso 2: Inicialización de la base de datos

```bash
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi
```

* Comprueba si MariaDB ya fue inicializada
* Evita borrar datos en reinicios

---

### Paso 3: Arranque temporal

```bash
mysqld &
```

* Arranca MariaDB en segundo plano
* Necesario para ejecutar comandos SQL

---

### Paso 4: Esperar a MariaDB

```bash
until mysqladmin ping; do
    sleep 1
done
```

* Evita ejecutar SQL antes de que MariaDB esté listo

---

### Paso 5: Leer secrets

```bash
DB_USER_PASS=$(cat "$WPDB_USER_PASSWORD_FILE")
DB_ROOT_PASS=$(cat "$WPDB_ROOT_PASSWORD_FILE")
MDB_ROOT_PASS=$(cat "$MDB_ROOT_PASSWORD_FILE")
```

* Las contraseñas **nunca están en el código**
* Cumple estrictamente el subject

---

### Paso 6: Crear base de datos y usuarios

```sql
CREATE DATABASE IF NOT EXISTS wordpress_db;
CREATE USER IF NOT EXISTS 'user'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON wordpress_db.* TO 'user'@'%';
```

* Base de datos para WordPress
* Usuario con permisos limitados

---

### Paso 7: Evitar reinicialización

```bash
touch /var/lib/mysql/.mysql_initialized
```

* Flag que indica que la DB ya está configurada

---

### Paso 8: Arranque final

```bash
exec mysqld
```

* MariaDB se ejecuta en primer plano
* El contenedor permanece activo

---

## Persistencia de datos

* Los datos se guardan en un **volumen del host**
* Ruta típica:

```
/home/<user>/data/mariadb
```

* Garantiza que los datos sobreviven a reinicios y rebuilds

---

## Resumen

* Si nunca has trabajado con Docker ni Inception:
* MariaDB es solo un contenedor, no un servicio instalado en tu máquina.
* Todo se configura automáticamente usando Dockerfile y entrypoint.
* No hay contraseñas en el código; se usan Docker secrets.
* Los datos se guardan fuera del contenedor, en un volumen persistente.
* WordPress se conecta a MariaDB a través de la red interna de Docker, no por Internet.
* El contenedor arranca y funciona de forma independiente, cumpliendo las normas de Inception.

## Para defensa

* MariaDB corre en su propio contenedor
* Usa Debian Bullseye
* No hay contraseñas en el código
* Los datos son persistentes
* La inicialización ocurre solo una vez
* WordPress se conecta por red interna Docker
