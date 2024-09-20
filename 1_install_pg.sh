#!/bin/bash

# ===========================
# Configuration Variables
# ===========================
PG_VERSION=15                      # PostgreSQL version
DB_NAME="mydb"                     # Database name
DB_USER="myuser"                   # Database user
DB_PASSWORD="mypassword"           # Database user password
ALLOW_REMOTE_CONNECTIONS=true      # Set to true to allow remote connections
IP_ALLOWLIST="0.0.0.0/0"           # IP range allowed to connect (if remote connections are enabled)
PG_CONF_DIR="/etc/postgresql/$PG_VERSION/main" # PostgreSQL configuration directory
# ===========================

# Update and install PostgreSQL
sudo apt-get update
sudo apt-get install -y "postgresql-$PG_VERSION" "postgresql-contrib-$PG_VERSION"

# Start PostgreSQL service
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Set up PostgreSQL user and database
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
echo "PostgreSQL $PG_VERSION and database '$DB_NAME' with user '$DB_USER' installed successfully."

# Configure PostgreSQL to allow remote connections if enabled
if [ "$ALLOW_REMOTE_CONNECTIONS" = true ]; then
  echo "Allowing remote connections..."

  # Update postgresql.conf to listen on all interfaces
  sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" "$PG_CONF_DIR/postgresql.conf"
  
  # Add rule to pg_hba.conf to allow connections from the specified IP allowlist
  echo "host    all             all             $IP_ALLOWLIST            md5" | sudo tee -a "$PG_CONF_DIR/pg_hba.conf"
  
  # Restart PostgreSQL to apply changes
  sudo systemctl restart postgresql
  echo "Remote connections are enabled and allowed from '$IP_ALLOWLIST'."
else
  echo "Remote connections are not enabled."
fi