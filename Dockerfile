FROM ubuntu:17.10
MAINTAINER Christian Lück <christian@lueck.tv>

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
  curl nginx supervisor php-fpm php-cli php-curl php-gd php-json \
  php-pgsql php-mysql php-mcrypt php-mbstring php-xml && apt-get clean && rm -rf /var/lib/apt/lists/*

# install ttrss and patch configuration
WORKDIR /var/www
RUN    curl -SL 'https://git.tt-rss.org/git/tt-rss/archive/17.4.tar.gz' | tar xzC /var/www --strip-components 1 \
    && chown www-data:www-data -R /var/www

RUN cp config.php-dist config.php && mkdir /var/run/php

# enable the mcrypt module
RUN phpenmod mcrypt
RUN phpenmod mbstring

# add ttrss as the only nginx site
ADD ttrss.nginx.conf /etc/nginx/sites-available/ttrss
RUN ln -s /etc/nginx/sites-available/ttrss /etc/nginx/sites-enabled/ttrss
RUN rm /etc/nginx/sites-enabled/default

# expose only nginx HTTP port
EXPOSE 80

# complete path to ttrss
ENV SELF_URL_PATH http://localhost

# expose default database credentials via ENV in order to ease overwriting
ENV DB_NAME ttrss
ENV DB_USER ttrss
ENV DB_PASS ttrss

# always re-configure database with current ENV when RUNning container, then monitor all services
ADD configure-db.php /configure-db.php
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD php /configure-db.php && supervisord -c /etc/supervisor/conf.d/supervisord.conf
