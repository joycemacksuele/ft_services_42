FROM alpine:latest

MAINTAINER Joyce Freitas <jfreitas@student.19.fr>

RUN apk update && apk upgrade

# For Alpine, rc-service is used, not systemctl or service
#RUN apk add openrc


############################## NGINX WEB SERVER ###############################
# Install Nginx web serve
# Nginx already creates /var/www for root web directory of Nginx
RUN apk add nginx

# USED HTML INSTEAD OF PHP, SINCE PHP EXTENTION HAS TO BE CONFIGURATED ON ALPINE
COPY ./index.html /var/www/

# The build of nginx is using /run/nginx/nginx.pid for the default PID location
# But it does not create the /run/nginx folder
RUN mkdir /run/nginx

# unknown user/group www:www
# Therefore a new user and group 'www' need to be created
RUN adduser -D -g 'www' www
# -D = Don't assign a password
# -g = Gecos field. Set general information about the account under ''
# LAST parameter = account name

RUN chown -R www:www /var/lib/nginx
RUN chown -R www:www /var/www
RUN chmod -R 755 /var/www # just in case it's not already like this
# 755 = u=rwx,go=rx (only user/owner can write)

COPY ./basic_nginx.conf /etc/nginx/nginx.conf
# COPY  will chage the name of the file basic_nginx.conf to nginx.conf,
# because nginx.conf does not exist as a directory or file


##################################### SSL #####################################
RUN apk add openssl
RUN mkdir -p /etc/nginx/ssl
# -p = No error if exists and make parent directories as needed
RUN openssl req -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out /etc/nginx/ssl/nginxssl.pem -keyout /etc/nginx/ssl/nginxssl.key -subj "/C=FR/ST=Paris/L=75017/O=42 school/CN=ft_services"


##################################### SSH #####################################
RUN apk add openssh

RUN /usr/bin/ssh-keygen -A
# ssh-keygen can be used to convert an OpenSSH public key to this file format
# -A = For each of the key types (rsa, dsa, ecdsa and ed25519) for which host
# keys do not exist, generate the host keys with the default key file path,
# an empty passphrase, default bits for the key type, and default comment

# Replacing custom message for SSH
RUN echo -e "\n---\nWelcome to the Nginx container - 42 ft_services project by jfreitas\n---\n" >> /etc/motd

# add ssh user: "user", with password: "password"
RUN adduser -D user
RUN echo "user:password" | /usr/sbin/chpasswd


EXPOSE 80 443 22

COPY ./start.sh /tmp/
RUN chmod +x /tmp/start.sh
CMD /tmp/start.sh
# CMD - specify what component is to be run by your image
