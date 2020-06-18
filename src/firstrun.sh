#!/bin/bash

start_mysql(){
    /usr/bin/mysqld_safe --datadir=/config/databases > /dev/null 2>&1 &
    RET=1
    while ! mysqladmin ping > /dev/null 2>&1; do
        sleep 1
    done
}

stop_mysql(){
    mysqladmin -u root shutdown
    RET=1
    while mysqladmin ping > /dev/null 2>&1; do
        sleep 1
    done
}



echo "**************************"
echo "** Begin of firstrun.sh **"
echo "**************************"

# Check if config for observium exists in volume. If not, copy the default config
if [ -f /config/config.php ]; then
    echo "Using existing PHP database config file from /config/config.php."
else
    echo "Loading PHP config from default."
    cp /opt/observium/config.php.default /config/config.php
    chown nobody:users /config/config.php
    PW=$(pwgen -1snc 32)
    sed -i -e 's/PASSWORD/'$PW'/g' /config/config.php
    sed -i -e 's/USERNAME/observium/g' /config/config.php
fi
ln -sf /config/config.php /opt/observium/config.php

#Setting timezone for php
if [ -f /etc/container_environment/TZ ] ; then
    echo "Timezone specified by environment variable."
else
    echo "Timezone not specified by environment variable. Using UTC"
    echo UTC > /etc/container_environment/TZ
fi
TZ=`cat /etc/container_environment/TZ`
echo "Setting timezone $TZ for php"
sed -i "s#\;date\.timezone\ \=#date\.timezone\ \=\ $TZ#g" /etc/php/7.2/cli/php.ini
sed -i "s#\;date\.timezone\ \=#date\.timezone\ \=\ $TZ#g" /etc/php/7.2/apache2/php.ini


# MYSQL
# Log to logdir
sed -i 's#^log_error = /var/log/mysql/error.log#log_error = /opt/obsevium/logfiles/mysql_error.log#' /etc/mysql/mariadb.conf.d/50-server.cnf

# If databases do not exist, create them
if [ -f /config/databases/observium/users.ibd ]; then
  echo "Database exists."
else
  echo "Initializing Database."
  mkdir -p /config/databases
  echo "Installation database in datadir."
  /usr/bin/mysql_install_db --datadir=/config/databases 
  echo "Starting mysql"
  start_mysql
  echo "Prepare database ans user for observium."
  mysql -u root -e "CREATE DATABASE IF NOT EXISTS observium DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
  PW=$(cat /config/config.php | grep -m 1 "'db_pass'" | sed -r 's/.*(.{34})/\1/;s/.{2}$//')
  mysql -u root -e "CREATE USER 'observium'@'localhost' IDENTIFIED BY '$PW'"
  echo "Database created. Granting access to 'observium' user for localhost."
  mysql -u root -e "GRANT ALL PRIVILEGES ON observium.* TO 'observium'@'localhost'"
  mysql -u root -e "FLUSH PRIVILEGES"
  cd /opt/observium
  echo "Preparing database schema for observium"
  php discovery.php -u
  echo "Creating default user and password for observium (observium/observium)"
  php adduser.php observium observium 10
  echo "Shutting down mysql."
  stop_mysql
  echo "Initialization of database complete."
fi


#Configure Mariadb
#RUN chown -R nobody:users /var/log/mysql && \
#    chown -R nobody:users /var/lib/mysql* && \
#    chown -R nobody:users /etc/mysql
#    chown -R nobody:users /var/run/mysqld


echo "**************************"
echo "** End of firstrun.sh **"
echo "**************************"
