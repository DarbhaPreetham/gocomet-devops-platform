# GoCommet DevOps Platform Makefile

.PHONY: help deploy status stop clean logs test backup restore

help: ## Show this help message
	@echo "GoCommet DevOps Platform - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

deploy: ## Deploy the entire platform
	@echo "🚀 Deploying GoCommet DevOps Platform..."
	@./scripts/deploy.sh

status: ## Check platform status
	@echo "🔍 Checking platform status..."
	@./scripts/status.sh

stop: ## Stop all services
	@echo "🛑 Stopping platform..."
	@docker-compose down

clean: ## Clean up containers and volumes
	@echo "🧹 Cleaning up..."
	@docker-compose down -v --remove-orphans
	@docker system prune -f

logs: ## Show logs for all services
	@echo "📋 Showing platform logs..."
	@docker-compose logs -f

test: ## Run platform tests
	@echo "🧪 Running platform tests..."
	@docker-compose exec sales-api npm test
	@docker-compose exec reporting-api python -m pytest

backup: ## Run manual backup
	@echo "💾 Running manual backup..."
	@docker-compose exec backup-service /scripts/backup-all.sh

restore: ## Restore from latest backup
	@echo "🔄 Restoring from backup..."
	@echo "Please specify backup file: make restore BACKUP_FILE=backup_file.sql"

dev: ## Start development environment
	@echo "🔧 Starting development environment..."
	@docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

prod: ## Start production environment
	@echo "🏭 Starting production environment..."
	@docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

scale: ## Scale services
	@echo "📈 Scaling services..."
	@docker-compose up -d --scale sales-api=3 --scale reporting-api=2

monitor: ## Open monitoring dashboards
	@echo "📊 Opening monitoring dashboards..."
	@echo "Grafana: http://localhost:3001"
	@echo "Prometheus: http://localhost:9090"
	@open http://localhost:3001 || echo "Please open http://localhost:3001 in your browser"

apps: ## Open application URLs
	@echo "🌐 Opening applications..."
	@echo "Sales Dashboard: http://localhost:3000"
	@echo "Internal Wiki: http://localhost:8080"
	@echo "Reporting API: http://localhost:5000"
	@open http://localhost:3000 || echo "Please open http://localhost:3000 in your browser"

security: ## Run security scan
	@echo "🔒 Running security scan..."
	@docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image sales-api:latest
	@docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image reporting-api:latest

update: ## Update platform components
	@echo "🔄 Updating platform..."
	@docker-compose pull
	@docker-compose up -d

secrets: ## Rotate secrets
	@echo "🔐 Rotating secrets..."
	@./scripts/rotate-secrets.sh

health: ## Check health of all services
	@echo "🏥 Checking service health..."
	@curl -s http://localhost:3001/health || echo "❌ Sales API unhealthy"
	@curl -s http://localhost:5000/health || echo "❌ Reporting API unhealthy"
	@curl -s http://localhost:8080 || echo "❌ WordPress unhealthy"
	@curl -s http://localhost:8200/v1/sys/health || echo "❌ Vault unhealthy"
	@curl -s http://localhost:9090/-/healthy || echo "❌ Prometheus unhealthy"
	@curl -s http://localhost:3001/api/health || echo "❌ Grafana unhealthy"
