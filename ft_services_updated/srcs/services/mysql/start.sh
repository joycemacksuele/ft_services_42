#!/bin/sh

############################ Initializing MariaDB #############################
# Initializing MySQL Data Directory and the tables in the mysql system database
openrc default
# rc-status Runlevel has to be set to defaul, not sysinit
# All runlevels are represented as folders in /etc/runlevels/ with symlinks to the actual init scripts.

/etc/init.d/mariadb setup

# starting the service but there's no root password set until this point
/etc/init.d/mariadb start


############### Starting MariaDB and Creating wordpress Database ##############
# Starting the MariaDB database server using a .sql file to create a wordpress database
/usr/bin/mysql < /tmp/create_db.sql


############################ Configutinf wordpress ############################
# Configuring the wordpress database using a .sql file
# Comment the line down below if you DON'T want to import a dump into the database
/usr/bin/mysql wordpress -u root --skip-password < /tmp/wordpress.sql
# Usage: mysql [OPTIONS] [database]
# Default options are read from the following files in the given order:
# /etc/my.cnf /etc/mysql/my.cnf ~/.my.cnf
# The following groups are read: mysql mariadb-client client client-server client-mariadb


########################### Starting MariaDB daemon ###########################
/etc/init.d/mariadb stop
/usr/bin/mysqld_safe --datadir="/var/lib/mysql"
# you need to set datadir to /var/lib/mysql (as standardized)
# mysqld_safe is a wrapper that can be used to start the mysqld server process.
# The script has some built-in safeguards, such as automatically restarting the server process if it dies.
