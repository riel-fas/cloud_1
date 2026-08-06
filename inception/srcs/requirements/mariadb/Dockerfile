FROM alpine:3.19


#Install MariaDB and required tools
RUN apk update && apk add --no-cache \
    mariadb \
    mariadb-client \
    && rm -rf /var/cache/apk/*

#Create necessary directories
RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    mkdir -p /var/lib/mysql && \
    chown -R mysql:mysql /var/lib/mysql

#Copy configuration file
COPY conf/mariadb.cnf /etc/my.cnf.d/mariadb.cnf

#Copy initialization script
COPY tools/init_db.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init_db.sh

#Expose MariaDB port
EXPOSE 3306

#Run the initialization script
ENTRYPOINT ["/usr/local/bin/init_db.sh"]
