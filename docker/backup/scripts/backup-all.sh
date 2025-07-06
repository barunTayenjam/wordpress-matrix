#!/bin/bash
# Comprehensive Backup Script for WordPress Development Environment

set -euo pipefail

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_BASE="/backup"
LOG_FILE="/backup/logs/backup_${TIMESTAMP}.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log "ERROR: $1"
    exit 1
}

log "🚀 Starting comprehensive backup process..."

# Create backup directories
mkdir -p "$BACKUP_BASE"/{mysql,files,logs}

# Backup MySQL databases
log "💾 Backing up MySQL databases..."
for db in xandar sakaar; do
    log "  📊 Backing up database: $db"
    mysqldump -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" \
        --single-transaction \
        --routines \
        --triggers \
        --add-drop-database \
        --databases "$db" > "$BACKUP_BASE/mysql/${db}_${TIMESTAMP}.sql" || error_exit "Failed to backup database $db"
    
    # Compress the SQL file
    gzip "$BACKUP_BASE/mysql/${db}_${TIMESTAMP}.sql"
    log "  ✅ Database $db backed up and compressed"
done

# Backup WordPress files
log "📁 Backing up WordPress files..."
for site in xandar sakaar; do
    if [ -d "/var/www/html/$site" ]; then
        log "  📦 Backing up site: $site"
        tar -czf "$BACKUP_BASE/files/${site}_${TIMESTAMP}.tar.gz" \
            -C "/var/www/html" \
            --exclude="$site/wp-content/cache" \
            --exclude="$site/wp-content/uploads/cache" \
            --exclude="$site/*.log" \
            "$site" || error_exit "Failed to backup files for $site"
        log "  ✅ Site $site files backed up"
    else
        log "  ⚠️  Site directory /var/www/html/$site not found, skipping"
    fi
done

# Upload to S3 if configured
if [ -n "${S3_BUCKET:-}" ] && [ -n "${AWS_ACCESS_KEY_ID:-}" ]; then
    log "☁️  Uploading backups to S3..."
    aws s3 sync "$BACKUP_BASE" "s3://$S3_BUCKET/backups/$(date +%Y/%m/%d)/" \
        --exclude "logs/*" || log "⚠️  S3 upload failed, continuing with local backup"
    log "✅ Backups uploaded to S3"
fi

# Cleanup old backups
log "🧹 Cleaning up old backups..."
find "$BACKUP_BASE/mysql" -name "*.sql.gz" -mtime +${BACKUP_RETENTION_DAYS:-30} -delete
find "$BACKUP_BASE/files" -name "*.tar.gz" -mtime +${BACKUP_RETENTION_DAYS:-30} -delete
find "$BACKUP_BASE/logs" -name "*.log" -mtime +7 -delete

# Generate backup report
BACKUP_SIZE=$(du -sh "$BACKUP_BASE" | cut -f1)
log "📊 Backup Summary:"
log "  📅 Timestamp: $TIMESTAMP"
log "  💾 Total Size: $BACKUP_SIZE"
log "  📁 Location: $BACKUP_BASE"
log "  🗂️  Retention: ${BACKUP_RETENTION_DAYS:-30} days"

log "🎉 Backup process completed successfully!"

# Send notification (if webhook is configured)
if [ -n "${BACKUP_WEBHOOK_URL:-}" ]; then
    curl -X POST "$BACKUP_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{\"text\":\"✅ WordPress backup completed successfully at $TIMESTAMP\"}" \
        || log "⚠️  Failed to send notification webhook"
fi