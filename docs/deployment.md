# GoCommet DevOps Platform - Deployment Guide

 🚀 Quick Start Deployment

# Prerequisites
- Docker 20.10+ and Docker Compose 2.0+
- Git
- 8GB RAM minimum
- 20GB free disk space

# One-Command Deployment
bash
git clone https://github.com/yourusername/gocomet-devops-platform.git
cd gocomet-devops-platform
./scripts/deploy.sh


# Manual Deployment Steps

 1. Clone Repository
bash
git clone https://github.com/yourusername/gocomet-devops-platform.git
cd gocomet-devops-platform


 2. Start Platform Infrastructure
bash
# Start core services (Vault, Monitoring, Databases)
docker-compose up -d vault prometheus grafana postgres mysql mongodb

# Wait for services to initialize
sleep 30


 3. Deploy Applications
bash
# Start sample applications
docker-compose up -d sales-api sales-frontend wordpress reporting-api

# Start supporting services
docker-compose up -d nginx backup-service


 4. Verify Deployment
bash
# Check service status
./scripts/status.sh

# View logs if needed
docker-compose logs -f


 🔧 Configuration

# Environment Variables
Create a `.env` file in the root directory:

bash
# Database Configuration
POSTGRES_DB=sales_db
POSTGRES_USER=sales_user
POSTGRES_PASSWORD=sales_password

MYSQL_ROOT_PASSWORD=root_password
MYSQL_DATABASE=wordpress_db
MYSQL_USER=wordpress_user
MYSQL_PASSWORD=wordpress_password

MONGODB_ROOT_USERNAME=admin
MONGODB_ROOT_PASSWORD=admin_password
MONGODB_DATABASE=reports_db

# Application Configuration
NODE_ENV=production
FLASK_ENV=production

# Vault Configuration
VAULT_DEV_ROOT_TOKEN_ID=gocomet-dev-token

# Monitoring Configuration
GRAFANA_ADMIN_PASSWORD=gocomet-admin


# Network Configuration
The platform uses a custom Docker network `gocomet-platform` for service isolation and communication.

# Port Mapping
- 3000: Sales Dashboard Frontend
- 3001: Sales API & Grafana
- 5000: Reporting API
- 8080: WordPress
- 8200: Vault UI
- 9090: Prometheus

 📊 Application Deployment

# Sales Dashboard
bash
# Build and deploy
docker-compose up -d sales-api sales-frontend postgres

# Check health
curl http://localhost:3001/health
curl http://localhost:3000


# Internal Wiki (WordPress)
bash
# Deploy WordPress
docker-compose up -d wordpress mysql

# Access WordPress setup
open http://localhost:8080


# Reporting API
bash
# Deploy Flask API
docker-compose up -d reporting-api mongodb

# Test API
curl http://localhost:5000/health
curl http://localhost:5000/api/reports


 🔐 Security Configuration

# Vault Setup
bash
# Initialize Vault (first time only)
docker-compose exec vault vault operator init

# Unseal Vault
docker-compose exec vault vault operator unseal

# Login to Vault
docker-compose exec vault vault auth -method=userpass username=admin password=admin


# SSL/TLS Configuration
1. Place SSL certificates in `platform/nginx/ssl/`
2. Update `platform/nginx/nginx.conf` with certificate paths
3. Restart nginx: `docker-compose restart nginx`

 📈 Monitoring Setup

# Prometheus Configuration
- Configuration: `platform/monitoring/prometheus.yml`
- Access: http://localhost:9090
- Targets: All services automatically discovered

# Grafana Setup
1. Access: http://localhost:3001
2. Login: admin / gocomet-admin
3. Import dashboards from `platform/monitoring/grafana/dashboards/`

# Custom Dashboards
Create custom dashboards in `platform/monitoring/grafana/dashboards/`:
- Application Performance
- Database Metrics
- Infrastructure Health
- Security Alerts

 🔄 Backup Configuration

# Automated Backups
Backups run daily at 2 AM via cron job:
bash
# Manual backup
docker-compose exec backup-service /scripts/backup-all.sh

# Check backup status
docker-compose logs backup-service


# Backup Locations
- PostgreSQL: `platform/backup/postgres/`
- MySQL: `platform/backup/mysql/`
- MongoDB: `platform/backup/mongodb/`

# Restore Process
bash
# PostgreSQL restore
docker-compose exec postgres psql -U sales_user -d sales_db < backup_file.sql

# MySQL restore
docker-compose exec mysql mysql -u wordpress_user -p wordpress_db < backup_file.sql

# MongoDB restore
docker-compose exec mongodb mongorestore --db reports_db backup_directory/


 🚀 Scaling

# Horizontal Scaling
bash
# Scale applications
docker-compose up -d --scale sales-api=3
docker-compose up -d --scale reporting-api=2

# Update nginx configuration for load balancing
docker-compose restart nginx


# Vertical Scaling
Update resource limits in `docker-compose.yml`:
yaml
services:
  sales-api:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G


 🔧 Maintenance

# Log Management
bash
# View logs
docker-compose logs -f [service-name]

# Rotate logs
docker-compose exec [service] logrotate /etc/logrotate.conf


# Database Maintenance
bash
# PostgreSQL maintenance
docker-compose exec postgres psql -U sales_user -d sales_db -c "VACUUM ANALYZE;"

# MySQL maintenance
docker-compose exec mysql mysql -u wordpress_user -p -e "OPTIMIZE TABLE wp_posts;"

# MongoDB maintenance
docker-compose exec mongodb mongosh --eval "db.runCommand({compact: 'reports'})"


# Security Updates
bash
# Update base images
docker-compose pull
docker-compose up -d

# Scan for vulnerabilities
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image [image-name]


 🚨 Troubleshooting

# Common Issues

 Services Not Starting
bash
# Check Docker status
docker info

# Check container logs
docker-compose logs [service-name]

# Restart specific service
docker-compose restart [service-name]


 Database Connection Issues
bash
# Check database connectivity
docker-compose exec postgres pg_isready -U sales_user
docker-compose exec mysql mysqladmin ping -h localhost
docker-compose exec mongodb mongosh --eval "db.adminCommand('ping')"


 Port Conflicts
bash
# Check port usage
netstat -tulpn | grep :3000

# Change ports in docker-compose.yml
# Update nginx configuration accordingly


# Health Checks
bash
# Platform health
./scripts/status.sh

# Individual service health
curl http://localhost:3001/health  # Sales API
curl http://localhost:5000/health    # Reporting API
curl http://localhost:8080          # WordPress


# Performance Issues
bash
# Check resource usage
docker stats

# Monitor logs for errors
docker-compose logs -f | grep ERROR

# Check database performance
docker-compose exec postgres psql -U sales_user -d sales_db -c "SELECT * FROM pg_stat_activity;"


 📋 Production Considerations

# Security Hardening
1. Change default passwords
2. Enable SSL/TLS
3. Configure firewall rules
4. Regular security updates
5. Implement secret rotation

# High Availability
1. Use external load balancer
2. Implement database replication
3. Set up monitoring alerts
4. Create disaster recovery plan

# Performance Optimization
1. Enable database query caching
2. Implement CDN for static assets
3. Configure connection pooling
4. Monitor and optimize queries

 �� Useful Commands

bash
# Platform management
./scripts/deploy.sh          # Deploy platform
./scripts/status.sh          # Check status
docker-compose down          # Stop platform
docker-compose up -d         # Start platform

# Service management
docker-compose restart [service]    # Restart service
docker-compose logs -f [service]     # View logs
docker-compose exec [service] bash  # Access container

# Database management
docker-compose exec postgres psql -U sales_user -d sales_db
docker-compose exec mysql mysql -u wordpress_user -p wordpress_db
docker-compose exec mongodb mongosh

# Backup management
docker-compose exec backup-service /scripts/backup-all.sh
ls -la platform/backup/*/

