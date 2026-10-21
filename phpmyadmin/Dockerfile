FROM phpmyadmin:latest

RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

COPY php-security/ensure-patched-php.sh /usr/local/bin/ensure-patched-php
RUN chmod +x /usr/local/bin/ensure-patched-php \
    && ensure-patched-php \
    && apache2ctl -t
