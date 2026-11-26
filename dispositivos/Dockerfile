FROM alpine:3.22
RUN apk add --no-cache net-snmp net-snmp-tools iproute2 iptables iperf3 stress-ng curl iputils busybox-extras
COPY snmpd.conf /etc/snmp/snmpd.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
