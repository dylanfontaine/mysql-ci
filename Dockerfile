FROM wyveo/nginx-php-fpm:php70

ENV WEB_ROOT /var/www/html

ADD ./nginx.conf /etc/nginx/conf.d/default.conf

# Set up nginx conf with our variables
RUN bash -c envsubst '\$WEB_ROOT' < /etc/nginx/conf.d/default.conf > /etc/nginx/conf.d/default.conf.tmp \
  && mv /etc/nginx/conf.d/default.conf.tmp /etc/nginx/conf.d/default.conf \
  && chown -Rf nginx.nginx $WEB_ROOT


RUN apt-get -y install apt-transport-https lsb-release ca-certificates \
    && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
    && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -q -y \
    libpng-dev \
    libjpeg-dev \
    libpq-dev \
    mysql-client \
    git \
    libbz2-dev \
    libgmp-dev \
    acl \
    gnupg \
    bc \
    bzip2 \
    openssh-server \
    make \
    ruby \
    shellcheck \
    rsync \
    php7.0-gmp \
    && rm -rf /var/lib/apt/lists/*

#install latest chrome
RUN curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

#install chromedriver
RUN CHROME_DRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE` \
  && wget -N http://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip -P ~/ \
  && unzip ~/chromedriver_linux64.zip -d ~/ \
  && rm ~/chromedriver_linux64.zip \
  && mv -f ~/chromedriver /usr/local/bin/chromedriver \
  && chmod 0755 /usr/local/bin/chromedriver

#install drush, to use for site and module installs
RUN wget https://github.com/drush-ops/drush/releases/download/8.2.3/drush.phar -O drush \
  && chmod +x drush \
&& mv drush /usr/local/bin

# Register the COMPOSER_HOME environment variable
ENV COMPOSER_HOME /composer

# Add global binary directory to PATH and make sure to re-export it
ENV PATH /composer/vendor/bin:$PATH

# Allow Composer to be run as root
ENV COMPOSER_ALLOW_SUPERUSER 1

# Install composer
RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
  && php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer && rm -rf /tmp/composer-setup.php

#allows for parallel composer downloads
RUN composer global require "hirak/prestissimo:^0.3"

#drupal console
RUN curl https://drupalconsole.com/installer -L -o drupal.phar \
  && chmod +x drupal.phar \
  && mv drupal.phar /usr/local/bin/drupal

#code standards
RUN curl -OL https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar \
 && chmod +x phpcs.phar \
 && mv phpcs.phar /usr/local/bin/phpcs

RUN composer global require drupal/coder phpmd/phpmd sebastian/phpcpd  smmccabe/phpdebt \
  && phpcs --config-set installed_paths /composer/vendor/drupal/coder/coder_sniffer

RUN wget https://raw.githubusercontent.com/smmccabe/readmecheck/master/readmecheck \
  && chmod +x readmecheck \
  && mv readmecheck /usr/local/bin/readmecheck

RUN curl -sL https://deb.nodesource.com/setup_8.x -o nodesource_setup.sh \
  && bash nodesource_setup.sh \
  && rm nodesource_setup.sh \
  && apt-get install -y nodejs

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
  && apt-get update && apt-get install yarn

# Install SensioLabs' security advisories checker
RUN curl -sL http://get.sensiolabs.org/security-checker.phar -o security-checker.phar \
  && chmod +x security-checker.phar \
  && mv security-checker.phar /usr/local/bin/security-checker

RUN ln -s /usr/bin/php /usr/local/bin/php
