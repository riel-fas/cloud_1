#!/bin/sh


set -e

# Increase PHP memory limit for wp-cli
echo "memory_limit = 256M" > /etc/php82/conf.d/99-memory.ini

echo "Starting WordPress setup..."

# Wait for MariaDB to be ready
#we need to ping directly if a port hange happens in mariadb
echo "Waiting for MariaDB to be ready..."
until mysqladmin ping -h"mariadb" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; do
    echo "MariaDB is unavailable - sleeping"
    sleep 2
done
echo "MariaDB is up and running!"

# Change to WordPress directory
cd /var/www/html

# Download WP-CLI if not exists
if [ ! -f /usr/local/bin/wp ]; then
    echo "Downloading WP-CLI..."
    wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp
    chmod +x /usr/local/bin/wp
fi

# Download WordPress if not exists
if [ ! -f wp-config.php ]; then
    echo "Downloading WordPress..."
    wp core download --allow-root
    
    echo "Creating wp-config.php..."
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb:3306" \
        --allow-root
    
    echo "Installing WordPress..."
    wp core install \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --allow-root
    
    echo "Creating additional WordPress user..."
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=editor \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root

    echo "Configuring Redis Object Cache..."
    wp config set WP_REDIS_HOST redis --allow-root
    wp config set WP_REDIS_PORT 6379 --raw --allow-root
    wp plugin install redis-cache --activate --allow-root
    wp redis enable --allow-root
    
    echo "WordPress installation complete!"
else
    echo "WordPress is already installed."
fi

# Set correct permissions
chown -R nobody:nobody /var/www/html

echo "Starting PHP-FPM..."
exec php-fpm82 -F
