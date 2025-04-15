#!/bin/bash

# Enable Traffic Control Filter (verified externally) on rtr1

if [ $(hostname) = "rtr1" ]; then
    echo "Configuring eBPF..."
    tc qdisc add dev eth0 clsact
    tc filter add dev eth0 egress protocol ipv6 prio 10 bpf da obj /src/ebpf-ipv6-exthdr-injection/build/tc_ipv6_eh_kern.o sec egress
    echo "eBPF configuration complete"
    /usr/local/bin/vtysh -c "config t" -c "router bgp" -c "address-family ipv6 unicast" -c "network 2001:11:11:11:FE01::/80" 
    sleep 1
fi

if [ $(hostname) = "rtr2" ]; then
    # Capture traffic to the cap directory to detect if injection is working
    tcpdump -i eth0 -U -w /cap/$(hostname)_$(date +"%Y%m%d_%H%M%S")_pretest.pcap
fi
