# main image
FROM php:8.3-apache

# installing main dependencies
RUN apt-get update && apt-get install -y \
    git \
    ffmpeg \
    libzip-dev \
    zlib1g-dev \
    unzip \
    libfreetype6-dev \
    libicu-dev \
    libgmp-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libxpm-dev \
    libmagickwand-dev

# Deployment arguments and environment
ARG user=appuser
ARG uid=1000
ARG container_project_path=/var/www/html

ENV user=${user}
ENV uid=${uid}
ENV container_project_path=${container_project_path}

# Create user only once!
RUN useradd -G www-data,root -u ${uid} -d /home/${user} ${user} \
    && mkdir -p /home/${user}/.composer \
    && chown -R ${user}:${user} /home/${user}

# Set permissions for project directory
RUN chmod -R 775 ${container_project_path} \
    && chown -R ${user}:www-data ${container_project_path}

# GD extension configure and install
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install gd

# imagick extension install
RUN pecl install imagick \
    && docker-php-ext-enable imagick

# intl extension install
RUN docker-php-ext-configure intl && docker-php-ext-install intl

# other extensions install
RUN docker-php-ext-install bcmath calendar exif gmp mysqli pdo pdo_mysql zip

# installing composer
COPY --from=composer:2.7 /usr/bin/composer /usr/local/bin/composer

# installing node js
COPY --from=node:23 /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node:23 /usr/local/bin/node /usr/local/bin/node
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

# installing global node dependencies
RUN npm install -g npx

# setting Apache site config
COPY ./.configs/apache.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# Re-apply permissions for project directory (in case COPY overwrites)
RUN chmod -R 775 ${container_project_path} \
    && chown -R ${user}:www-data ${container_project_path}

# change to your user
USER ${user}

# set work directory
WORKDIR ${container_project_path}
