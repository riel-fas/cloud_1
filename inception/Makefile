COMPOSE_FILE = srcs/docker-compose.yml
DATA_PATH = /home/riel-fas/data


GREEN = \033[0;32m
RED = \033[0;31m
YELLOW = \033[0;33m
NC = \033[0m # No Color

all: build up

#Build all Docker images
build:
	@echo "$(YELLOW)Building Docker images...$(NC)"
	docker compose -f $(COMPOSE_FILE) build
	@echo "$(GREEN)Build complete!$(NC)"

#Start all containers
up:
	@echo "$(YELLOW)Starting containers...$(NC)"
	docker compose -f $(COMPOSE_FILE) up -d --build
	@echo "$(GREEN)Containers are running!$(NC)"
	@echo ""
	@echo "$(GREEN)=============================================$(NC)"
	@echo "$(GREEN)           🚀 ACCESS URLS 🚀                 $(NC)"
	@echo "$(GREEN)=============================================$(NC)"
	@echo "$(GREEN)🌐 WordPress:       https://riel-fas.42.fr$(NC)"
	@echo "$(GREEN)🗃️  Adminer:         http://riel-fas.42.fr:8080$(NC)"
	@echo "$(GREEN)📊 Redis Commander: http://riel-fas.42.fr:8082$(NC)"
	@echo "$(GREEN)🎮 Chat Bot:  	   http://riel-fas.42.fr:3000$(NC)"
	@echo "$(GREEN)=============================================$(NC)"

#Stop all containers
down:
	@echo "$(YELLOW)Stopping containers...$(NC)"
	docker compose -f $(COMPOSE_FILE) down
	@echo "$(GREEN)Containers stopped!$(NC)"

#Stop and remove containers, networks, volumes, and images
clean: down
	@echo "$(RED)Cleaning up containers, networks, and volumes...$(NC)"
	docker compose -f $(COMPOSE_FILE) down -v --rmi all
	@echo "$(GREEN)Cleanup complete!$(NC)"

#Remove all data from volumes
fclean: clean
	@echo "$(RED)Removing all data...$(NC)"
	sudo rm -rf $(DATA_PATH)/wordpress/*
	sudo rm -rf $(DATA_PATH)/mariadb/*
	@echo "$(GREEN)All data removed!$(NC)"

#Full rebuild
re: fclean all

#Show status of containers
status:
	@echo "$(YELLOW)Container status:$(NC)"
	docker compose -f $(COMPOSE_FILE) ps

#Show logs
logs:
	docker compose -f $(COMPOSE_FILE) logs -f

#Show logs for a specific service (usage: make logs-service SERVICE=nginx)
logs-service:
	docker compose -f $(COMPOSE_FILE) logs -f $(SERVICE)

#Execute shell in a container (usage: make shell SERVICE=nginx)
shell:
	docker compose -f $(COMPOSE_FILE) exec $(SERVICE) /bin/sh

#Restart all services
restart: down up

.PHONY: all build up down clean fclean re status logs logs-service shell restart