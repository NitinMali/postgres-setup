#!/bin/bash

# ===========================
# Configuration Variables
# ===========================
DB_NAME="devdb"
DB_USER="devdbuser"
DB_PASSWORD="devdbuser"
S3_BUCKET=""
BACKUP_DIR="/var/backups/postgresql"
AWS_ACCESS_KEY_ID=""
AWS_SECRET_ACCESS_KEY=""
AWS_REGION="ap-south-1"
CRON_TIME="30 10,20 * * *"  # At 10:30 AM and 20:30 PM daily


# Export AWS credentials to avoid aws configure prompt
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

# ===========================
# Install AWS CLI and configure
# ===========================
if ! command -v aws &> /dev/null
then
    echo "AWS CLI not found. Installing..."
    sudo apt-get update
    sudo apt-get install zip unzip
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
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

# Take the database backup
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_$(date +%F_%T).sql"

# ===========================
# Cron Job Setup
# ===========================
# Schedule a cron job to backup PostgreSQL and send to S3
BACKUP_COMMAND="pg_dump -U $DB_USER -F c $DB_NAME > $BACKUP_FILE && aws s3 cp $BACKUP_FILE s3://$S3_BUCKET/ --region $AWS_REGION"

# Check if the cron job already exists
(crontab -l | grep "$BACKUP_PATH") > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Cron job already exists."
else
    # Add the new cron job to run the backup directly
    (crontab -l 2>/dev/null; echo "$CRON_TIME $BACKUP_COMMAND") | crontab -
    echo "Cron job scheduled: $CRON_TIME"
fi
echo "Backup process scheduled to run at $CRON_TIME"

# ===========================
# Immediate Backup (Optional)
# ===========================
# Run immediate backup (optional step)
#echo "Running immediate backup..."
PGPASSWORD="$DB_PASSWORD" pg_dump -U $DB_USER $DB_NAME > $BACKUP_DIR/$(date +\%Y-%m-%d-%H)-backup.sql

# Upload the backup to S3
aws s3 cp $BACKUP_DIR/$(date +\%Y-%m-%d-%H)-backup-onrun.sql s3://$S3_BUCKET/ --region $AWS_REGION

# Clean up old backups (older than 7 days)
#find $BACKUP_DIR -type f -mtime +7 -name '*.sql' -exec rm {} \;

echo "Backup completed and uploaded to S3."
