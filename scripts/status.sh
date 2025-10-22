#!/bin/bash

# GoCommet DevOps Platform Status Check
echo "🔍 GoCommet DevOps Platform Status"
echo "=================================="

# Check Docker Compose services
echo ""
echo "📦 Container Status:"
docker-compose ps

echo ""
echo "🌐 Service Health Checks:"

# Function to check service health
check_service() {
    local name=$1
    local url=$2
    local expected_status=${3:-200}
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "$expected_status"; then
        echo "✅ $name: Healthy"
    else
        echo "❌ $name: Unhealthy"
    fi
}

# Check all services
check_service "Vault" "http://localhost:8200/v1/sys/health"
check_service "Prometheus" "http://localhost:9090/-/healthy"
check_service "Grafana" "http://localhost:3001/api/health"
check_service "Sales API" "http://localhost:3001/health"
check_service "Reporting API" "http://localhost:5000/health"
check_service "WordPress" "http://localhost:8080"

echo ""
echo "💾 Database Connections:"

# Check PostgreSQL
if docker-compose exec -T postgres pg_isready -U sales_user > /dev/null 2>&1; then
    echo "✅ PostgreSQL: Connected"
else
    echo "❌ PostgreSQL: Disconnected"
fi

# Check MySQL
if docker-compose exec -T mysql mysqladmin ping -h localhost > /dev/null 2>&1; then
    echo "✅ MySQL: Connected"
else
    echo "❌ MySQL: Disconnected"
fi

# Check MongoDB
if docker-compose exec -T mongodb mongosh --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
    echo "✅ MongoDB: Connected"
else
    echo "❌ MongoDB: Disconnected"
fi

echo ""
echo "📊 Resource Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | head -10

echo ""
echo "🔗 Quick Access Links:"
echo "   • Sales Dashboard: http://localhost:3000"
echo "   • Internal Wiki: http://localhost:8080"
echo "   • Reporting API: http://localhost:5000"
echo "   • Vault UI: http://localhost:8200"
echo "   • Grafana: http://localhost:3001"
echo "   • Prometheus: http://localhost:9090"
