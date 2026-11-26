FROM alpine:3.22

RUN apk add --no-cache \
    bash \
    net-snmp \
    net-snmp-tools \
    iproute2 \
    iptables \
    iperf3 \
    stress-ng \
    curl \
    iputils \
    nginx \
    procps \
    tcpdump

COPY snmpd.conf /etc/snmp/snmpd.conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh && \
    sed -i 's/\r$//' /entrypoint.sh /etc/snmp/snmpd.conf

ENTRYPOINT ["/entrypoint.sh"]
