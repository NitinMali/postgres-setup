#!/bin/bash

# ===========================
# Configuration Variables
# ===========================
DB_NAME="your_database"
S3_BUCKET="your-s3-bucket-name"
BACKUP_DIR="/var/backups/postgresql"
AWS_ACCESS_KEY_ID="your-aws-access-key-id"
AWS_SECRET_ACCESS_KEY="your-aws-secret-access-key"
AWS_REGION="your-aws-region"
CRON_TIME="30 10,20 * * *"  # At 10:30 AM and 20:30 PM daily
DB_USER="postgres"
DB_PASSWORD="your-postgres-password"

# ===========================
# Install AWS CLI and configure
# ===========================
if ! command -v aws &> /dev/null
then
    echo "AWS CLI not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y awscli
else
    echo "AWS CLI is already installed."
fi

# Configure AWS CLI
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set region $AWS_REGION

# ===========================
# Backup Directory
# ===========================
# Create backup directory if not exists
sudo mkdir -p $BACKUP_DIR

# ===========================
# Cron Job Setup
# ===========================
# Schedule a cron job to backup PostgreSQL and send to S3
(crontab -l 2>/dev/null; echo "$CRON_TIME PGPASSWORD=\"$DB_PASSWORD\" pg_dump -U $DB_USER $DB_NAME > $BACKUP_DIR/$(date +\%Y-\%m-\%d-\%H)-backup.sql && aws s3 cp $BACKUP_DIR/$(date +\%Y-\%m-\%d-\%H)-backup.sql s3://$S3_BUCKET/ && find $BACKUP_DIR -type f -mtime +7 -name '*.sql' -exec rm {} \;") | crontab -

echo "Backup process scheduled to run at $CRON_TIME"

# ===========================
# Immediate Backup (Optional)
# ===========================
# Run immediate backup (optional step)
#echo "Running immediate backup..."
#PGPASSWORD="$DB_PASSWORD" pg_dump -U $DB_USER $DB_NAME > $BACKUP_DIR/$(date +\%Y-%m-%d-%H)-backup.sql

# Upload the backup to S3
aws s3 cp $BACKUP_DIR/$(date +\%Y-%m-%d-%H)-backup.sql s3://$S3_BUCKET/

# Clean up old backups (older than 7 days)
find $BACKUP_DIR -type f -mtime +7 -name '*.sql' -exec rm {} \;

echo "Backup completed and uploaded to S3."
