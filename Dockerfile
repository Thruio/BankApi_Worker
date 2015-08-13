FROM phusion/baseimage:latest
MAINTAINER Matthew Baggett <matthew@baggett.me>

CMD ["/sbin/my_init"]

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

# Install base packages
RUN apt-get update && \
    apt-get -yq install \
        wget \
        curl \
        git \
        apache2 \
        nodejs npm \
        nano \
        libapache2-mod-php5 \
        php5-mysql \
        php5-gd \
        php5-curl \
        php-pear \
        php5-dev \
        nmap \
        redis-server \
        apt-utils \
        sudo \
        net-tools \
        telnet \
        jq \
        netcat-openbsd \
        iputils-ping \
        unzip \
        pwgen \
        bc \
        php-apc && \
    rm -rf /var/lib/apt/lists/*
RUN sed -i "s/variables_order.*/variables_order = \"EGPCS\"/g" /etc/php5/apache2/php.ini
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

ENV TZ "Europe/London"
RUN echo $TZ | tee /etc/timezone \
  && dpkg-reconfigure --frontend noninteractive tzdata

# Enable mod_rewrite
RUN a2enmod rewrite && /etc/init.d/apache2 restart

# Add image configuration and scripts
ADD run.sh /run.sh
RUN chmod 755 /*.sh

# Configure /app folder with sample app
RUN mkdir -p /app && rm -fr /var/www/html && ln -s /app /var/www/html
ADD . /app
#ADD .htaccess /app/.htaccess
ADD ApacheConfig.conf /etc/apache2/sites-enabled/000-default.conf

# Run Composer
RUN cd /app && composer update

# Run NPM install
#RUN cd /app && npm install

# Add our crontab file
ADD crons.conf /crons.conf

# Use the crontab file
RUN crontab /crons.conf

# Start cron
CMD cron

EXPOSE 80

WORKDIR /app
CMD ["/run.sh"]
