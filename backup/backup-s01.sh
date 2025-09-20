#!/bin/bash
# Backup script for server s01
# NOTE: Run this script as a user with appropriate permissions to access Nginx configuration files.
#.      
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
BACKUP_DIR="/home/"$USER"/backup/s01"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_NAME="nginx_backup_s01_$TIMESTAMP.tar.gz"   

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR"  || { echo "Failed to change directory to "$BACKUP_DIR""; exit 1; }
# Create the archive
tar -czf "$ARCHIVE_NAME" "$NGINX_CONF" "$NGINX_SITES" "$NGINX_SITES_ENABLED" "$NGINX_SSL" || { echo "Failed to create archive "$ARCHIVE_NAME""; exit 1; }
# Verify if the archive was created successfully
if [ $? -ne 0 ]; then
    echo -e "${RED}Error:${RESET} Backup creation failed!"
    exit 1
fi
chown "$USER":"$USER" "$ARCHIVE_NAME"

echo "Backup created successfully: "$BACKUP_DIR"/"$ARCHIVE_NAME""
# Remove backups older than 90 days
find "$BACKUP_DIR" -type f -name "nginx_backup_s01_*.tar.gz" -mtime +90 -exec rm {} \; || echo "No old backups to remove."

echo "Backups older than 90 are days removed."     
# End of script