FROM wordpress:php8.3-fpm

COPY php-security/ensure-patched-php.sh /usr/local/bin/ensure-patched-php
RUN chmod +x /usr/local/bin/ensure-patched-php \
    && ensure-patched-php

# Install system dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    unzip \
    wget \
    libfcgi-bin \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd zip opcache

# Install Redis extension via PECL
RUN set -eu; \
    attempt=1; \
    until pecl install redis; do \
        if [ "$attempt" -ge 5 ]; then exit 1; fi; \
        attempt=$((attempt + 1)); \
        sleep 5; \
    done \
    && docker-php-ext-enable redis

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Install php-fpm-healthcheck
RUN wget -O /usr/local/bin/php-fpm-healthcheck \
    https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck \
    && chmod +x /usr/local/bin/php-fpm-healthcheck

# Enable PHP-FPM status page for healthcheck
RUN echo "pm.status_path = /status" >> /usr/local/etc/php-fpm.d/zz-docker.conf

# Copy custom entrypoint
COPY wordpress/docker-entrypoint-custom.sh /usr/local/bin/docker-entrypoint-custom.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-custom.sh

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html

RUN ensure-patched-php --check-only && php-fpm -t

ENTRYPOINT ["docker-entrypoint-custom.sh"]
CMD ["php-fpm"]
