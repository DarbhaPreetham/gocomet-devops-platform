#!/bin/bash

# GoCommet DevOps Platform Deployment Script
echo "🚀 Starting GoCommet DevOps Platform Deployment..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p platform/backup/{postgres,mysql,mongodb}
mkdir -p platform/nginx/ssl

# Set proper permissions
chmod +x scripts/*.sh

# Start the platform
echo "🐳 Starting Docker containers..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 30

# Check service health
echo "🔍 Checking service health..."

# Check Vault
if curl -s http://localhost:8200/v1/sys/health > /dev/null; then
    echo "✅ Vault is healthy"
else
    echo "❌ Vault is not responding"
fi

# Check Prometheus
if curl -s http://localhost:9090/-/healthy > /dev/null; then
    echo "✅ Prometheus is healthy"
else
    echo "❌ Prometheus is not responding"
fi

# Check Grafana
if curl -s http://localhost:3001/api/health > /dev/null; then
    echo "✅ Grafana is healthy"
else
    echo "❌ Grafana is not responding"
fi

# Check Sales API
if curl -s http://localhost:3001/health > /dev/null; then
    echo "✅ Sales API is healthy"
else
    echo "❌ Sales API is not responding"
fi

# Check Reporting API
if curl -s http://localhost:5000/health > /dev/null; then
    echo "✅ Reporting API is healthy"
else
    echo "❌ Reporting API is not responding"
fi

echo ""
echo "🎉 GoCommet DevOps Platform is now running!"
echo ""
echo "📊 Access your applications:"
echo "   • Sales Dashboard: http://localhost:3000"
echo "   • Internal Wiki: http://localhost:8080"
echo "   • Reporting API: http://localhost:5000"
echo "   • Vault UI: http://localhost:8200"
echo "   • Grafana: http://localhost:3001 (admin/gocomet-admin)"
echo "   • Prometheus: http://localhost:9090"
echo ""
echo "🔧 Management commands:"
echo "   • View logs: docker-compose logs -f [service]"
echo "   • Stop platform: docker-compose down"
echo "   • Restart service: docker-compose restart [service]"
echo "   • Check status: ./scripts/status.sh"
echo ""
