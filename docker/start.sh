#!/bin/sh
set -e

echo "Starting Laravel application..."

php artisan config:cache
php artisan route:cache
php artisan storage:link --force

echo "Starting PHP-FPM..."
php-fpm -D

echo "Starting Nginx..."
nginx -g "daemon off;"