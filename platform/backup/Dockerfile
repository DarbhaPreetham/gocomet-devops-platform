FROM alpine:latest

# Install required packages
RUN apk add --no-cache \
    postgresql-client \
    mysql-client \
    mongodb-tools \
    bash \
    curl \
    tar \
    gzip

# Create backup directories
RUN mkdir -p /backup/postgres /backup/mysql /backup/mongodb

# Copy backup scripts
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

# Ensure backup script is executable and has proper shebang
RUN chmod +x /scripts/backup-all.sh

# Set up cron job
RUN echo "0 2 * * * /scripts/backup-all.sh" | crontab -

# Start cron daemon
CMD ["crond", "-f"]
