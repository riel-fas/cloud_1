FROM alpine:3.19

#Install PHP-FPM and required extensions for WordPress
RUN apk update && apk add --no-cache \
    php82 \
    php82-fpm \
    php82-ctype \
    php82-mysqli \
    php82-json \
    php82-curl \
    php82-dom \
    php82-exif \
    php82-fileinfo \
    php82-mbstring \
    php82-openssl \
    php82-xml \
    php82-zip \
    php82-phar \
    php82-intl \
    php82-gd \
    php82-iconv \
    php82-simplexml \
    php82-xmlreader \
    php82-zlib \
    php82-tokenizer \
    php82-session \
    php82-pecl-redis \
    mariadb-client \
    wget \
    bash \
    && rm -rf /var/cache/apk/*

#Create necessary directories
RUN mkdir -p /var/www/html && \
    mkdir -p /var/log/php82 && \
    chown -R nobody:nobody /var/www/html

#Copy PHP-FPM configuration
COPY conf/www.conf /etc/php82/php-fpm.d/www.conf

#Copy WordPress installation script
COPY tools/setup_wordpress.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup_wordpress.sh

#Set working directory
WORKDIR /var/www/html

#Expose PHP-FPM port
EXPOSE 9000

#Run the setup script
ENTRYPOINT ["/usr/local/bin/setup_wordpress.sh"]

