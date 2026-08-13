FROM alpine:3.19


#Install NGINX
RUN apk update && apk add --no-cache nginx

#Copy the NGINX configuration and website files
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY www/ /var/www/html/

#Necessary directories for nginx
RUN mkdir -p /run/nginx

#Expose the port
EXPOSE 3000

#Run the static website
CMD ["nginx", "-g", "daemon off;"]
