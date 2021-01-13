FROM alpine:latest

MAINTAINER Joyce Freitas <jfreitas@student.19.fr>

RUN apk update && apk upgrade
RUN apk add openrc


#################################### MYSQL ####################################
# Alpine has dummy counterparts packages for those that are not close to the
# change from mysql to mariadb naming packages
RUN apk add mysql mysql-client
# mysql = dummy package to easy install of server equivalent to mysql-server
# mysql-client = dummy package to easy install of command line and tools

RUN mkdir -p /run/mysqld
# 2 users will be created during instalation of packages: root and mysql
# The group mysql is also already created
RUN chown -R mysql:mysql /run/mysqld
RUN chmod -R 755 /var/lib/mysql # just in case it's not already like this

COPY ./mariadb-server.cnf /etc/my.cnf.d/mariadb-server.cnf
COPY ./create_db.sql /tmp/
COPY ./wordpress.sql /tmp/


EXPOSE 3306

COPY ./start.sh /tmp/
RUN chmod +x /tmp/start.sh
CMD /tmp/start.sh
