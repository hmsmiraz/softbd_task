FROM php:8.3-fpm-alpine AS production

LABEL maintainer="softbd_task"

RUN apk add --no-cache \
    nginx \
    curl \
    libpng-dev \
    libzip-dev \
    zip \
    unzip \
    && docker-php-ext-install \
        pdo_mysql \
        zip \
        gd \
        pcntl \
        bcmath \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && pecl install redis-6.0.2 \
    && docker-php-ext-enable redis \
    && apk del .build-deps

RUN addgroup -g 1000 -S www && \
    adduser -u 1000 -S www -G www

RUN mkdir -p /var/lib/nginx/logs \
             /var/lib/nginx/tmp/client_body \
             /var/lib/nginx/tmp/proxy \
             /var/lib/nginx/tmp/fastcgi \
             /var/log/nginx \
             /run/nginx \
    && chown -R www:www /var/lib/nginx \
                        /var/log/nginx \
                        /run/nginx \
    && chmod -R 755 /var/lib/nginx \
                    /var/log/nginx \
                    /run/nginx

WORKDIR /var/www/html

COPY --chown=www:www . .

COPY docker/nginx/default.conf /etc/nginx/http.d/default.conf

COPY docker/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

RUN mkdir -p storage/logs \
             storage/framework/sessions \
             storage/framework/views \
             storage/framework/cache \
             bootstrap/cache \
    && chown -R www:www /var/www/html \
    && chmod -R 755 storage bootstrap/cache

USER www

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

CMD ["/usr/local/bin/start.sh"]