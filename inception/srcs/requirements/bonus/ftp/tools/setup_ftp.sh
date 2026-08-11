#!/bin/sh


set -e

echo "Setting up FTP server..."

#Create FTP user if it doesn't exist
if ! id -u "${FTP_USER}" > /dev/null 2>&1; then
    echo "Creating FTP user: ${FTP_USER}"
    adduser -D -h /var/www/html "${FTP_USER}"
    echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd
fi

#Create WordPress directory if it doesn't exist
mkdir -p /var/www/html
chown -R ${FTP_USER}:${FTP_USER} /var/www/html

#Create log directory
mkdir -p /var/log/vsftpd
chown -R ${FTP_USER}:${FTP_USER} /var/log/vsftpd

echo "FTP server configured!"
echo "User: ${FTP_USER}"
echo "Password: ${FTP_PASSWORD}"

#Start vsftpd
echo "Starting vsftpd..."
exec /usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf
