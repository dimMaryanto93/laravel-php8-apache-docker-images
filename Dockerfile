FROM repository.dimas-maryanto.com:8086/php:8.0-apache as php_laravel

# install dependencies for laravel 8
RUN apt-get update && apt-get install -y \
          libicu-dev \
          libpq-dev \
          libmcrypt-dev \
          git \
          zip \
          unzip \
          zlib1g-dev \
          libpng-dev \
          libzip-dev \
          openssl \
    && rm -r /var/lib/apt/lists/*

# install extension for laravel 8
RUN pecl install mcrypt-1.0.4 && \
  docker-php-ext-install fileinfo pdo pdo_pgsql pdo_mysql exif pcntl bcmath gd  && \
  docker-php-ext-enable mcrypt

# install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

FROM repository.dimas-maryanto.com:8086/node:14-alpine3.10 as node_module_install
WORKDIR /var/www/html
COPY package.json /var/www/html
COPY package-lock.json /var/www/html
RUN npm install

FROM php_laravel as executeable

ENV APP_SOURCE /var/www/html

# Add user for laravel application
RUN groupadd -g 1000 www
RUN useradd -u 1000 -ms /bin/bash -g www www
# Set working directory
WORKDIR $APP_SOURCE

# copy source laravel
COPY . $APP_SOURCE
# setup env
RUN mv $APP_SOURCE/.env.production $APP_SOURCE/.env
# copy node_modules from npm install
COPY --from=node_module_install /var/www/html $APP_SOURCE
# change ownership of our applications
COPY --chown=www:www . $APP_SOURCE/
# allow to read
RUN chmod -R 777 $APP_SOURCE

# install dependency laravel
RUN composer install --no-interaction --optimize-autoloader --no-dev && \
    php artisan optimize && \
    php artisan route:clear && \
    php artisan view:clear && \
    php artisan config:clear && \
    php artisan key:generate

# expose port default 80
EXPOSE 80
