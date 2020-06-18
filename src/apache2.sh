#!/bin/bash


echo "**************************"
echo "** Begin of apache2.sh **"
echo "**************************"

set -e
exec /usr/sbin/apache2 -D FOREGROUND

echo "**************************"
echo "** End of apache2.sh **"
echo "**************************"
