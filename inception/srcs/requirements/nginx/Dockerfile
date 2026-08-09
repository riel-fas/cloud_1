FROM alpine:3.19

#Install NGINX and OpenSSL
RUN apk update && apk add --no-cache \
    nginx \
    openssl \
    && rm -rf /var/cache/apk/*

#Create necessary directories
RUN mkdir -p /etc/nginx/ssl \
    && mkdir -p /var/run/nginx \
    && mkdir -p /var/www/html

#Copy NGINX configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/default.conf /etc/nginx/http.d/default.conf

#Copy SSL certificate generation script
COPY tools/generate_ssl.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/generate_ssl.sh

#Generate SSL certificates
RUN /usr/local/bin/generate_ssl.sh

#Expose HTTPS port only
EXPOSE 443

#Start NGINX in foreground
CMD ["nginx", "-g", "daemon off;"]

