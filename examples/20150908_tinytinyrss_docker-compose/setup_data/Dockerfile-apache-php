FROM php:5.6-apache
RUN apt-get update && apt-get install -y php5-pgsql php5-curl && rm /etc/apache2/mods-available/php5.load && apt-get install -y libapache2-mod-php5
COPY php.ini /usr/local/etc/php/

