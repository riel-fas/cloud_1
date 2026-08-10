FROM alpine:3.19


#Install Node.js and npm
RUN apk update && apk add --no-cache \
    nodejs \
    npm \
    && rm -rf /var/cache/apk/*

#Install redis-commander globally
RUN npm install -g redis-commander

#Expose Redis Commander port
EXPOSE 8081

#Run redis-commander
CMD ["redis-commander", "--redis-host", "redis", "--redis-port", "6379", "--port", "8081"]
