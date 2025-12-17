## Preparación del entorno (antes de Inception)

Aquí se describe **paso a paso** cómo preparar correctamente el entorno necesario
antes de comenzar el proyecto **Inception**.
Siguiendo este orden se evitan problemas posteriores con Docker, permisos o compatibilidad.

---

## 1. Elección e instalación de la Máquina Virtual

### Sistema Operativo requerido

El proyecto Inception debe desarrollarse dentro de una **máquina virtual Linux**.
Las distribuciones recomendadas son:

* Debian (recomendado)
* Ubuntu Server

En este proyecto se utiliza:

```
Debian 11 (Bullseye)
```

**Motivos de la elección**:

* Versión estable y ampliamente soportada
* Total compatibilidad con Docker
* Recomendado por la escuela 42
* Coincide con la base usada en los contenedores

---

### Software de virtualización

Se puede usar cualquiera de los siguientes:

* VirtualBox
* VMware
* UTM (macOS ARM)

**Configuración mínima recomendada**:

* 2 CPU
* 4 GB RAM
* 20–30 GB de disco
* Red en modo NAT o Bridge

---

## 2. Instalación inicial del sistema

Durante la instalación de Debian:

* Instalar únicamente:

  * SSH server
  * Standard system utilities
* No instalar entorno gráfico
* Crear un usuario normal (no root)

Ejemplo:

```
usuario: mvidal-h
```

---

## 3. Actualización del sistema

Nada más iniciar sesión en la máquina virtual:

```bash
sudo apt update && sudo apt upgrade -y
```

Esto garantiza:

* Sistema actualizado
* Correcciones de seguridad
* Compatibilidad con Docker

---

## 4. Instalación de Docker

Docker no viene instalado por defecto en Debian y debe añadirse manualmente.

### Instalación de dependencias

```bash
sudo apt install -y ca-certificates curl gnupg lsb-release
```

### Añadir la clave oficial de Docker

```bash
curl -fsSL https://download.docker.com/linux/debian/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg
```

### Añadir el repositorio estable

```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] \
https://download.docker.com/linux/debian $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### Instalar Docker Engine

```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
```

### Verificación

```bash
docker --version
```

---

## 5. Instalación de Docker Compose

Docker Compose es imprescindible para orquestar múltiples contenedores.

```bash
sudo apt install -y docker-compose-plugin
```

Comprobación:

```bash
docker compose version
```

---

## 6. Configuración de permisos Docker

Para poder usar Docker sin `sudo`:

```bash
sudo usermod -aG docker $USER
```

⚠️ Es obligatorio cerrar sesión y volver a entrar.

Comprobación:

```bash
docker ps
```

---

## 7. ¿Cuándo se escribe el código?

Antes de instalar la máquina virtual:

* ❌ No es necesario escribir código
* ❌ No se debe crear el proyecto en el host

El desarrollo comienza **después** de que Docker funcione correctamente en la VM.

Orden correcto:

1. Instalar VM
2. Instalar Docker
3. Probar Docker
4. Crear estructura del proyecto
5. Escribir Dockerfiles
6. Crear docker-compose.yml
7. Crear Makefile
8. Añadir bonus

---

## 8. Elección de versiones (Debian / Alpine)

El subject exige que las imágenes se construyan a partir de la **penúltima versión estable**.

Ejemplo Debian:

* Stable: Debian 12 (Bookworm)
* Penúltima estable: **Debian 11 (Bullseye)**

Por eso se utiliza:

```Dockerfile
FROM debian:bullseye
```

Nunca se debe usar `latest`.

---

## 9. Buenas prácticas obligatorias

* No usar imágenes `latest`
* No hardcodear contraseñas
* Usar Docker secrets
* Un servicio por contenedor
* NGINX como único punto de entrada
* Datos persistentes en volúmenes

---

Esta Informacion cubre **exclusivamente** la preparación del entorno.
La estructura del proyecto y los servicios se documentan en el ` README ` principal.
