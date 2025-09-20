#!/bin/bash
# Backup script for server s01
# NOTE: Run this script as a user with appropriate permissions to access Nginx configuration files.
#.      Create an environment variable for the user running the script.
#       Example: export ADMIN_USER="your_username"
# Define variables
# Color codes for terminal output
RED='\e[31m'
GREEN='\e[32m'
BLUE='\e[34m'
BOLD='\e[1m'
RESET='\e[0m'

NGINX_CONF="/etc/nginx/nginx.conf"
NGINX_SITES="/etc/nginx/sites-available"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"
NGINX_SSL="/etc/letsencrypt"
DOC_ROOT="/var/www/"
FAIL2BAN="/etc/fail2ban"
BACKUP_DIR="/home/"$ADMIN_USER"/backup/s01"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_NAME="nginx_backup_s01_$TIMESTAMP.tar.gz"   
MYSQL_DUMP_NAME="mysql_backup_s01_$TIMESTAMP.sql.gz"
# TODO: Add user environment variable definition for admin tasks
# Ensure USER variable is set
if [ -z "$ADMIN_USER" ]; then
    echo -e "${RED}Error:${RESET} USER environment variable is not set. Please set it to the appropriate username."
    exit 1
fi
# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR"  || { echo "Failed to change directory to "$BACKUP_DIR""; exit 1; }

# Create the archive
tar -czf "$ARCHIVE_NAME" "$NGINX_CONF" "$NGINX_SITES" "$NGINX_SITES_ENABLED" "$NGINX_SSL" "$DOC_ROOT" "$FAIL2BAN" "$MYSQL_DUMP_NAME" || { echo "Failed to create archive "$ARCHIVE_NAME""; exit 1; }
# Verify if the archive was created successfully
if [ $? -ne 0 ]; then
    echo -e "${RED}Error:${RESET} Backup creation failed!"
    exit 1
fi
chown "$ADMIN_USER":"$ADMIN_USER" "$ARCHIVE_NAME"

echo "Backup created successfully: "$BACKUP_DIR"/"$ARCHIVE_NAME""
# Remove backups older than 90 days
find "$BACKUP_DIR" -type f -name "nginx_backup_s01_*.tar.gz" -mtime +90 -exec rm {} \; || echo "No old backups to remove."

echo "Backups older than 90 are days removed."     
# End of script