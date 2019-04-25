FROM wyveo/nginx-php-fpm:php70

ADD ./nginx.conf /etc/nginx/conf.d/default.conf

CMD chown -Rf nginx.nginx /builds/telus/commerce/

CMD service nginx reload

RUN apt-get update && apt-get install -y libpng-dev libjpeg-dev libpq-dev mysql-client git libbz2-dev libgmp-dev acl gnupg bc bzip2
RUN apt-get update && apt-get install -y gnupg
RUN rm -rf /var/lib/apt/lists/*

#install latest chrome
RUN curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list
RUN apt-get update && apt-get install -y google-chrome-stable

#install chromedriver
RUN CHROME_DRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE` \
  && wget -N http://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip -P ~/ \
  && unzip ~/chromedriver_linux64.zip -d ~/ \
  && rm ~/chromedriver_linux64.zip \
  && mv -f ~/chromedriver /usr/local/bin/chromedriver \
  && chmod 0755 /usr/local/bin/chromedriver

# Install Ruby.
RUN \
  apt-get update && \
  apt-get install -y ruby

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

RUN composer global require drupal/coder \
  && phpcs --config-set installed_paths /composer/vendor/drupal/coder/coder_sniffer

RUN composer global require phpmd/phpmd

RUN composer global require sebastian/phpcpd

RUN composer global require smmccabe/phpdebt

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

RUN apt-get install shellcheck
