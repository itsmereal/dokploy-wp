FROM alpine:3.24

# Install required packages
RUN apk upgrade --no-cache && apk add --no-cache bash curl unzip

# Copy the installation script
COPY install-redis-plugin.sh /install-redis-plugin.sh
RUN chmod +x /install-redis-plugin.sh

ENTRYPOINT ["/install-redis-plugin.sh"]
