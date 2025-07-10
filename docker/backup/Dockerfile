FROM alpine:3.18

# Install required packages
RUN apk add --no-cache \
    bash \
    curl \
    mysql-client \
    aws-cli \
    rsync \
    tar \
    gzip \
    cron \
    tzdata \
    && rm -rf /var/cache/apk/*

# Install restic for advanced backups
RUN wget -O restic.bz2 https://github.com/restic/restic/releases/download/v0.16.0/restic_0.16.0_linux_amd64.bz2 \
    && bunzip2 restic.bz2 \
    && chmod +x restic \
    && mv restic /usr/local/bin/

# Copy backup scripts
COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*

# Create backup directories
RUN mkdir -p /backup/mysql /backup/files /backup/logs

# Setup cron
COPY crontab /etc/crontabs/root
RUN chmod 0644 /etc/crontabs/root

# Create entrypoint
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'echo "🔒 Backup Service Starting..."' >> /entrypoint.sh && \
    echo 'echo "📅 Backup Schedule: $BACKUP_SCHEDULE"' >> /entrypoint.sh && \
    echo 'echo "🗂️  Retention: $BACKUP_RETENTION_DAYS days"' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Setup cron schedule' >> /entrypoint.sh && \
    echo 'echo "$BACKUP_SCHEDULE /usr/local/bin/backup-all.sh" > /etc/crontabs/root' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Start cron daemon' >> /entrypoint.sh && \
    echo 'crond -f -d 8' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]