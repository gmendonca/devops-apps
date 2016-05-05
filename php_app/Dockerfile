FROM ubuntu:trusty

RUN apt-get update -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y curl libapache2-mod-php5 php5 php5-mcrypt
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf
RUN a2enmod rewrite

ADD run.sh /run.sh
RUN chmod 755 /*.sh

RUN mkdir -p /php-app && rm -fr /var/www/html && ln -s /php-app/web /var/www/html
ADD . /php-app
WORKDIR /php-app

RUN composer install --no-interaction

RUN chown -R www-data:www-data /php-app -R

EXPOSE 80

CMD ["/run.sh"]
