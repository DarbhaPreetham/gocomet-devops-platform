#!/bin/bash

# Backup all databases
echo "Starting backup process at $(date)"

# PostgreSQL backup
echo "Backing up PostgreSQL..."
pg_dump -h postgres -U sales_user -d sales_db > /backup/postgres/sales_db_$(date +%Y%m%d_%H%M%S).sql

# MySQL backup
echo "Backing up MySQL..."
mysqldump -h mysql -u wordpress_user -pwordpress_password wordpress_db > /backup/mysql/wordpress_db_$(date +%Y%m%d_%H%M%S).sql

# MongoDB backup
echo "Backing up MongoDB..."
mongodump --host mongodb --username admin --password admin_password --db reports_db --out /backup/mongodb/reports_db_$(date +%Y%m%d_%H%M%S)

# Compress backups
echo "Compressing backups..."
cd /backup
tar -czf postgres_backup_$(date +%Y%m%d_%H%M%S).tar.gz postgres/
tar -czf mysql_backup_$(date +%Y%m%d_%H%M%S).tar.gz mysql/
tar -czf mongodb_backup_$(date +%Y%m%d_%H%M%S).tar.gz mongodb/

# Clean up old backups (keep last 7 days)
echo "Cleaning up old backups..."
find /backup -name "*.sql" -mtime +7 -delete
find /backup -name "*.tar.gz" -mtime +7 -delete

echo "Backup process completed at $(date)"
