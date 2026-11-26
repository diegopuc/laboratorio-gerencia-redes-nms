#!/bin/sh
set -eu
mkdir -p /www
printf '<h1>%s</h1>\n' "$(hostname)" > /www/index.html
busybox httpd -p 8080 -h /www
iperf3 -s -D
exec snmpd -f -Lo -C -c /etc/snmp/snmpd.conf
