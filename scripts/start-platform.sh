#!/bin/bash

# GoComet DevOps Platform Startup Script
echo "🚀 Starting GoComet DevOps Platform..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Navigate to project directory
cd "$(dirname "$0")/.."

# Create necessary directories if they don't exist
echo "📁 Creating necessary directories..."
mkdir -p platform/nginx/ssl
mkdir -p platform/backup/{postgres,mysql,mongodb}

# Start the platform
echo "🐳 Starting Docker containers..."
docker-compose up -d

# Wait a moment for services to start
echo "⏳ Waiting for services to initialize..."
sleep 10

# Check service status
echo "📊 Platform Status:"
echo "==================="
echo "🌐 Sales Dashboard: http://localhost:3000"
echo "📊 Sales API: http://localhost:3001"
echo "📝 Internal Wiki: http://localhost:8080"
echo "📈 Reporting API: http://localhost:5000"
echo "📊 Grafana: http://localhost:3002"
echo "🔍 Prometheus: http://localhost:9090"
echo "🔐 Vault: http://localhost:8200"
echo "🌐 Nginx Proxy: http://localhost:80"

echo ""
echo "✅ GoComet DevOps Platform is running!"
echo "Use 'docker-compose logs -f' to view logs"
echo "Use 'docker-compose down' to stop the platform"
