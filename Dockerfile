FROM phusion/baseimage:bionic-1.0.0 

# Set correct environment variables.
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Use baseimage-docker's init system
CMD ["/sbin/my_init"]

# Configure user nobody to match unRAID's settings
 RUN \
 usermod -u 99 nobody && \
 usermod -g 100 nobody && \
 usermod -d /home nobody && \
 chown -R nobody:users /home

# Install locales
RUN locale-gen cs_CZ.UTF-8 && \
    locale-gen de_DE.UTF-8 && \
    locale-gen en_US.UTF-8 && \
    locale-gen es_ES.UTF-8 && \
    locale-gen fr_FR.UTF-8 && \
    locale-gen it_IT.UTF-8 && \
    locale-gen pl_PL.UTF-8 && \
    locale-gen pt_BR.UTF-8 && \
    locale-gen ru_RU.UTF-8 && \
    locale-gen sl_SI.UTF-8 && \
    locale-gen uk_UA.UTF-8

RUN apt-add-repository universe && \
    apt-add-repository multiverse

#Establish Preconditions for Observium
RUN apt-get update -q && \
    apt-get install -y --no-install-recommends  libapache2-mod-php7.2 php7.2-cli php7.2-mysql \
        php7.2-mysqli php7.2-gd php7.2-json php-pear snmp fping mariadb-server mariadb-client \
        python-mysqldb rrdtool subversion whois mtr-tiny ipmitool graphviz imagemagick apache2 wget pwgen && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#Get Obsservium
RUN mkdir -p /opt/observium && \
    cd /opt && \
    wget -nv https://www.observium.org/observium-community-latest.tar.gz && \
    tar zxf observium-community-latest.tar.gz --owner=nobody --group=users && \
    chmod 755 -R /opt/observium && \
    rm observium-community-latest.tar.gz

#Prepare mountpoints for volumes 
RUN mkdir -p /opt/observium/logs /opt/observium/rrd /config && \
    chown www-data:www-data /opt/observium/rrd
VOLUME ["/config","/opt/observium/logs","/opt/observium/rrd"]

# Configure apache2 to serve Observium app
COPY src/apache2.conf /etc/apache2/apache2.conf
COPY src/ports.conf /etc/apache2/ports.conf
COPY src/apache-observium /etc/apache2/sites-available/000-default.conf
RUN rm /etc/apache2/sites-available/default-ssl.conf && \
    echo www-data > /etc/container_environment/APACHE_RUN_USER && \
    echo www-data > /etc/container_environment/APACHE_RUN_GROUP && \
    echo /var/log/apache2 > /etc/container_environment/APACHE_LOG_DIR && \
    echo /var/lock/apache2 > /etc/container_environment/APACHE_LOCK_DIR && \
    echo /var/run/apache2.pid > /etc/container_environment/APACHE_PID_FILE && \
    echo /var/run/apache2 > /etc/container_environment/APACHE_RUN_DIR && \
    chown -R www-data:www-data /var/log/apache2 && \
    rm -Rf /var/www && \
    ln -s /opt/observium/html /var/www

#Configure apache	
RUN phpenmod mcrypt && \
    a2dismod mpm_event && \
    a2enmod mpm_prefork && \
    a2enmod php7.2 && \
    a2enmod rewrite && \
    apache2ctl restart

#Cron for observium
COPY src/observium.cron /etc/cron.d/observium

#Add Apache Daemon
RUN mkdir /etc/service/apache2
COPY src/apache2.sh /etc/service/apache2/run
RUN chmod +x /etc/service/apache2/run

#Add MariaDB Daemon
RUN mkdir /etc/service/mariadb
COPY src/mariadb.sh /etc/service/mariadb/run
RUN chmod +x /etc/service/mariadb/run

#Add initialisation script
COPY src/firstrun.sh /etc/my_init.d/firstrun.sh
RUN chmod +x /etc/my_init.d/firstrun.sh

EXPOSE 8668/tcp

HEALTHCHECK --interval=30s --timeout=5s --start-period=180s CMD curl --fail http://localhost:8668 > /dev/null 2>&1 || exit 1