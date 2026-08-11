FROM alpine:3.19


#Install PHP and required extensions for Adminer
RUN apk update && apk add --no-cache \
    php82 \
    php82-session \
    php82-mysqli \
    php82-pgsql \
    php82-sqlite3 \
    php82-pdo \
    php82-pdo_mysql \
    php82-pdo_pgsql \
    php82-pdo_sqlite \
    php82-json \
    wget \
    && rm -rf /var/cache/apk/*

#Create directory and download Adminer
RUN mkdir -p /var/www \
    && wget "https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php" -O /var/www/adminer.php

#Create a simple index.html that redirects to adminer.php
RUN echo '<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0; url=/adminer.php"></head><body>Redirecting to Adminer...</body></html>' > /var/www/index.html

#Expose port
EXPOSE 8080

#Run PHP built-in server
CMD ["php82", "-S", "0.0.0.0:8080", "-t", "/var/www"]
