FROM php:7.4-apache
LABEL maintainer="Andrei Daniel Petrica"

ENV DEBIAN_FRONTEND noninteractive
# you can change this to your timezone
ENV TZ=UTC

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install --reinstall python  python3.9-minimal -y && \
    apt-get install -y supervisor git curl > /dev/null

# Tool for php extensions instalation
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
# Make it executable
RUN chmod +x /usr/local/bin/install-php-extensions

RUN install-php-extensions pdo_mysql zip > /dev/null
RUN install-php-extensions gd calendar exif bcmath intl > /dev/null

# Change apache root
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

RUN mkdir -p /var/log/supervisor
# Add user for laravel application
# Aggiunto questo codice per permetere di entrare nella machina e modificare file come www-data e
#  non aver problemi di permessi poi sui file se modificati al contrario di quando si entra con root
RUN useradd -G www-data,root -u 1000 -d /home/phuser phuser \
	&& mkdir -p /home/phuser/.composer \
	&& chown -R phuser:www-data /home/phuser \
	&& chown -R phuser:www-data /var/www/html \
	&& chown -R phuser:www-data /var/log/supervisor
# RUN mkdir /home/www-data www-data \
# RUN mkdir /home/www-data www-data \
#      mkdir -p /home/www-data/.composer \
# 	&& chown -R www-data:www-data /home/www-data

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
COPY --chown=root:root  docker_conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker_conf/php.ini /etc/php/7.4/cli/conf.d/99-sail.ini

# Change current user to phpuser
USER phuser

WORKDIR /var/www/html

EXPOSE 8000

# Start supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
