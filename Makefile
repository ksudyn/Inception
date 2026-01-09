# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: ksudyn <ksudyn@student.42.fr>              +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/01/09 18:11:24 by ksudyn            #+#    #+#              #
#    Updated: 2026/01/09 18:13:35 by ksudyn           ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

NAME = inception

# Ruta al archivo docker-compose
COMPOSE = docker-compose -p $(NAME) -f srcs/docker-compose.yml


# make  -> levanta todo el proyecto
all: up

# Construir imágenes y levantar contenedores
up:
	$(COMPOSE) up -d --build

# Detener contenedores sin borrar datos
down:
	$(COMPOSE) down


# Detener contenedores y borrar volúmenes
# Elimina bases de datos y uploads
clean:
	$(COMPOSE) down -v

# Limpieza TOTAL del proyecto
fclean:
	$(COMPOSE) down -v --rmi all

# Reconstrucción completa
re: fclean all

# Mostrar estado de contenedores
ps:
	$(COMPOSE) ps

# Ver logs en tiempo real
logs:
	$(COMPOSE) logs -f

# Evitar conflictos si existe un archivo con el mismo nombre
.PHONY: all up down clean fclean re ps logs
