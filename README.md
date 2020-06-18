# Observium

Docker container for Observium. Created with the intend to have a simple to set up observium for 64bit operating systems running on the Raspberry Pi 4

Observium is a low-maintenance auto-discovering network monitoring platform supporting a wide range of device types, platforms and operating systems including Cisco, Windows, Linux, HP, Juniper, Dell, FreeBSD, Brocade, Netscaler, NetApp and many more. Observium focuses on providing a beautiful and powerful yet simple and intuitive interface to the health and status of your network.

# Container
The provided container is based on the Phusion baseimage (bioninc-1.0.0) which is based on Ubuntu 18.4 and includes everything needed to rund observium. A MariaDB instance is included and observium is configured to use the internal database. It uses 3 volumes to store config, logs, database and RRDs which have to be attached to the followning paths:
- /config
- /opt/observium/logs
- /opt/observium/rrd

Observium is exposed at port 8668
The container also provides a healthcheck


# Building
Build from docker file:
<pre><code>git clone git@github.com:cleverware/observium.git
cd observium
docker build -t cleverware/observium .</pre></code>
You can also pull the ready container via:
<pre><code>docker pull cleverware/observium</code></pre>

# Running
<pre><code>docker run -d -v /config-volume-location:/config -v /logs-volume-location:/opt/observium/logs -v /rrds-volume-location:/opt/observium/rrd -p 8668:8668 cleverware/observium</code></pre>
When the container is up and reports a healthy status browse to 
```http://<docker-host-ip>:8668```
and loging with username observium and password observium.

> Don't forget to change the default password
