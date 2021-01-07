FROM alpine:latest

MAINTAINER Joyce Freitas <jfreitas@student.19.fr>

RUN apk update && apk upgrade
RUN apk add openrc


##################################### PHP #####################################
# default PHP on alpine 3.x is 7 https://pkgs.alpinelinux.org/package/edge/community/x86/php7
RUN apk add php7 php7-fpm
# Also add popular PHP modules
RUN apk add php7-mbstring php7-gd php7-cli php7-mysqli php7-opcache php7-zlib php7-curl php7-json php7-session php7-cgi

RUN mkdir -p /var/run/php


############################## NGINX WEB SERVER ###############################
RUN apk add nginx
RUN mkdir /run/nginx
COPY ./basic_nginx.conf /etc/nginx/nginx.conf


################################# PhpMyAdmin ##################################
RUN wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-english.tar.gz

# tmp directory where phpMyAdmin will store its temporary files
RUN mkdir -p /var/www/phpmyadmin/tmp
RUN chmod -R o=wxr /var/www/phpmyadmin/tmp

RUN tar -xvf phpMyAdmin-latest-english.tar.gz --strip-components=1 -C /var/www/phpmyadmin
COPY ./phpmyadmin.inc.php /var/www/phpmyadmin/config.inc.php


################################ Nginx config #################################
# Set variables to use later to edit www.conf and php.ini files
# to make Nginx work with PHP
ENV PHP_FPM_USER="www" \
	PHP_FPM_GROUP="www" \
	PHP_FPM_LISTEN_MODE="0660" \
	PHP_MEMORY_LIMIT="512M" \
	PHP_MAX_UPLOAD="50M" \
	PHP_MAX_FILE_UPLOAD="200" \
	PHP_MAX_POST="100M" \
	PHP_DISPLAY_ERRORS="On" \
	PHP_DISPLAY_STARTUP_ERRORS="On" \
	PHP_ERROR_REPORTING="E_COMPILE_ERROR\|E_RECOVERABLE_ERROR\|E_ERROR\|E_CORE_ERROR" \
	PHP_CGI_FIX_PATHINFO=0

RUN adduser -D -g 'www' www
RUN chown -R www:www /var/lib/nginx
RUN chown -R www:www /var/www
RUN chmod -R 755 /var/www


EXPOSE 5000

COPY ./start.sh /tmp/
RUN chmod +x /tmp/start.sh
CMD /tmp/start.sh
