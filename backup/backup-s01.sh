#!/bin/bash
# Backup script for server with Nginx, MySQL, and Fail2Ban
# Backs up Nginx configuration files, website data, MySQL databases, and Fail2Ban configurations.
# Saves the backup in a timestamped tar.gz archive in the specified backup directory.
# Also removes backups older than 90 days.
# NOTE: Run this script as a user with appropriate permissions to access Nginx configuration files.
#.      Create environment variables for the script using the .env file.
#       Example: ADMIN_USER="your_username"
#                DB_USER="your_username"
#                DB_PASSWORD="your_password"
# Define variables
# Color codes for terminal output
RED='\e[31m'
GREEN='\e[32m'
BLUE='\e[34m'
BOLD='\e[1m'
RESET='\e[0m'

WORKING_DIR="/home/"$ADMIN_USER"/myscripts/backup"
NGINX_CONF="/etc/nginx/nginx.conf"
NGINX_SITES="/etc/nginx/sites-available"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"
NGINX_SSL="/etc/letsencrypt"
DOC_ROOT="/var/www/"
FAIL2BAN="/etc/fail2ban"
BACKUP_DIR="/home/"$ADMIN_USER"/backup/s01"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_NAME="backup_server_s01_$TIMESTAMP.tar.gz"   
MYSQL_DBS="mysql_backup_DBS_$TIMESTAMP.sql.gz"

# Ensure environment variables are set
if [[ -f ""$WORKING_DIR"/.env" ]]; then
    set -a
    source "$WORKING_DIR"/.env
    set +a
else
    echo -e "${RED}Error:${RESET} .env file not found. Please create a .env file with the required environment variables and assign their values: ADMIN_USER, DB_USER, DB_PASSWORD."
    exit 1
fi

if [ -z "$ADMIN_USER" ]; then
    echo -e "${RED}Error:${RESET} USER environment variable is not set. Please set it to the appropriate username."
    exit 1
fi
# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR"  || { echo "Failed to change directory to "$BACKUP_DIR""; exit 1; }

mysqldump -u $DB_USER -p$DB_PASSWORD --all-databases | gzip > "$MYSQL_DBS"
if [ $? -ne 0 ]; then
    echo -e "${RED}Error:${RESET} MySQL dump creation failed!"
    exit 1
fi

# Create the archive
tar -czf "$ARCHIVE_NAME" "$NGINX_CONF" "$NGINX_SITES" "$NGINX_SITES_ENABLED" "$NGINX_SSL" "$DOC_ROOT" "$FAIL2BAN" "$MYSQL_DBS" 
# Verify if the backup was created successfully
if [ $? -ne 0 ]; then
    echo -e "${RED}Error:${RESET} Backup creation failed!"
    exit 1
fi

# Remove the temporary MySQL dump file
rm "$MYSQL_DBS"

# Set ownership to ADMIN_USER
chown "$ADMIN_USER":"$ADMIN_USER" "$ARCHIVE_NAME"

echo "Backup created successfully: "$BACKUP_DIR"/"$ARCHIVE_NAME""
# Remove backups older than 90 days
find "$BACKUP_DIR" -type f -name "nginx_backup_s01_*.tar.gz" -mtime +90 -exec rm {} \; || echo "No old backups to remove."

echo "Backups older than 90 are days removed."     
# End of script