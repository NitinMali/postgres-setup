#!/bin/bash

# ===========================
# Configuration Variables
# ===========================
PG_VERSION=15                      # PostgreSQL version
DB_NAME="db"                     # Database name
DB_USER="dev"                   # Database user
DB_PASSWORD="devdbuser"           # Database user password
ALLOW_REMOTE_CONNECTIONS=true      # Set to true to allow remote connections
IP_ALLOWLIST="0.0.0.0/0"           # IP range allowed to connect (if remote connections are enabled)
PG_CONF_DIR="/etc/postgresql/$PG_VERSION/main" # PostgreSQL configuration directory
# ===========================

# Update package list and install prerequisites
sudo apt-get update
sudo apt-get install -y wget gnupg2 lsb-release

# Add PostgreSQL Apt Repository
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list

# Update package list again after adding the repository
sudo apt-get update

# Install PostgreSQL
sudo apt-get install -y "postgresql-$PG_VERSION" "postgresql-contrib-$PG_VERSION"

# Check if PostgreSQL was installed successfully
if ! dpkg -l | grep -q "postgresql-$PG_VERSION"; then
    echo "PostgreSQL installation failed. Please check the logs."
    exit 1
fi

# Start PostgreSQL service
sudo systemctl enable postgresql
sudo systemctl start postgresql
    # Check if the PostgreSQL service is running
if ! sudo systemctl is-active --quiet postgresql; then
    echo "PostgreSQL service failed to start. Please check the logs for details."
    exit 1
fi

# Change permission for home directory
#sudo chown -R postgres:postgres /home/ubuntu/postgres-setup

# Set up PostgreSQL user and database
sudo -u postgres psql -d postgres -c "CREATE DATABASE $DB_NAME;"
sudo -u postgres psql -d postgres -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
sudo -u postgres psql -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
echo "PostgreSQL $PG_VERSION and database '$DB_NAME' with user '$DB_USER' installed successfully."

# Configure PostgreSQL to allow remote connections if enabled
if [ "$ALLOW_REMOTE_CONNECTIONS" = true ]; then
    echo "Allowing remote connections..."
    PG_CONF_DIR="/etc/postgresql/$PG_VERSION/main"

    # Update postgresql.conf to listen on all interfaces
    if [ -f "$PG_CONF_DIR/postgresql.conf" ]; then
        sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" "$PG_CONF_DIR/postgresql.conf"
    else
        echo "PostgreSQL configuration file not found."
        exit 1
    fi

    # Add rule to pg_hba.conf to allow connections from the specified IP allowlist
    if [ -f "$PG_CONF_DIR/pg_hba.conf" ]; then
        echo "host    all             all             $IP_ALLOWLIST            md5" | sudo tee -a "$PG_CONF_DIR/pg_hba.conf"
    else
        echo "PostgreSQL pg_hba.conf file not found."
        exit 1
    fi

    # Restart PostgreSQL to apply changes
    sudo systemctl restart postgresql
    echo "Remote connections are enabled and allowed from '$IP_ALLOWLIST'."
else
    echo "Remote connections are not enabled."
fi