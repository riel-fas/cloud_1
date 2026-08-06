#!/bin/sh


#Exit on error
set -e

echo "Starting MariaDB initialization..."

#Create log directory
mkdir -p /var/log/mysql
chown -R mysql:mysql /var/log/mysql

#Check if database is already initialized
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    
    #Initialize the database
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
    
    echo "MariaDB data directory initialized."
fi

#Start MariaDB temporarily in the background for setup
echo "Starting temporary MariaDB instance..."
mysqld --user=mysql --bootstrap --verbose=0 --skip-networking=0 << EOF
USE mysql;
FLUSH PRIVILEGES;

-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';

-- Remove remote root access
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Create database
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

-- Create user and grant privileges
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

-- Apply changes
FLUSH PRIVILEGES;
EOF

echo "MariaDB initialization complete!"
echo "Database: ${MYSQL_DATABASE}"
echo "User: ${MYSQL_USER}"

#Start MariaDB in the foreground
echo "Starting MariaDB server..."
exec mysqld --user=mysql --console
