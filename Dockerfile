FROM alpine:latest

MAINTAINER Björn Ramberg

# Install specific version of apache web server
RUN apk --update add apache2 && \
    echo '<html><body>Hello World!</body></html>' > /var/www/localhost/htdocs/index.html && \
    mkdir -p /run/apache2/

# Expose the port 
EXPOSE 80

# Start the apache daemon and set it as the contianer entrypoint
ENTRYPOINT ["httpd"]
CMD ["-D", "FOREGROUND"]
