#!/bin/bash

echo "**************************"
echo "** Begin of mariadb.sh **"
echo "**************************"

echo "Starting MariaDB..."
/usr/bin/mysqld_safe --datadir='/config/databases'

while mysqladmin ping > /dev/null 2>&1; do 
    sleep 5
done

echo "**************************"
echo "** End of mariadb.sh **"
echo "**************************"
