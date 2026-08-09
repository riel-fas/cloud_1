#!/bin/sh

#Exit on error
set -e

echo "Generating SSL certificate for riel-fas.42.fr..."

#Generate self-signed SSL certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=FR/ST=Paris/L=Paris/O=42/OU=riel-fas/CN=riel-fas.42.fr"

#Set correct permissions
chmod 600 /etc/nginx/ssl/nginx.key
chmod 644 /etc/nginx/ssl/nginx.crt

echo "SSL certificate generated successfully!"

