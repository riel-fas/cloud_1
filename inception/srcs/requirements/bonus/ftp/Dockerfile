FROM alpine:3.19


#Install vsftpd and necessary tools
RUN apk update && apk add --no-cache \
    vsftpd \
    shadow \
    bash \
    && rm -rf /var/cache/apk/*

#Create FTP user directory and set permissions
RUN mkdir -p /var/ftp && \
    chmod 755 /var/ftp

#Copy configuration
COPY conf/vsftpd.conf /etc/vsftpd/vsftpd.conf

#Copy setup script
COPY tools/setup_ftp.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup_ftp.sh

#Expose FTP ports
EXPOSE 21 21000-21010

#Run setup script
ENTRYPOINT ["/usr/local/bin/setup_ftp.sh"]
