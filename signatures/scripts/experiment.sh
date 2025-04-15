#!/bin/bash

# Enable instrumentation on each host before running the experiment on rtr1
# Enable job control 
set -m

# Capture traffic to the cap directory, labeled by host
tcpdump -i eth0 -U -w /cap/$(hostname)_$(date +"%Y%m%d_%H%M%S").pcap &

# Create log file and allow others to read
touch /cap/log.txt
chmod o+r /cap/log.txt


# Estimate future time experiment will complete before starting instrumentation
ft=$(($(date +%s) + 1001))
ft=$(date -d @$ft)

# Add marker to logs
echo "---START $(date +"%Y%m%d_%H%M%S")---" >> /cap/log.txt
# Start Instrumentation
pfix=$(date +"%Y%m%d_%H%M%S")
vmstat -n 1 100000 > /cap/$(hostname)_$(date +"%Y%m%d_%H%M%S").vmstat &
vmspid=$!
( while true; do sh -c "cat /sys/fs/cgroup/memory.current >> /cap/$pfix.memcur"; sleep 1; done; ) &

# Run Experiment
if [ $(hostname) = "rtr1" ]; then # only originate routes from rtr1
    echo "***Experiment starting; no output will appear until the experiment is complete around $ft"
    for i in {1..250}
    do
        for j in {1..4}
        do
            address=$(printf "2001:11:11:11:%02x%02x::/80" $j $i)
            /usr/local/bin/vtysh -c "config t" -c "router bgp" -c "address-family ipv6 unicast" -c "network $address" 2>/dev/null
            sleep 1
        done
    done
    /usr/local/bin/vtysh -c "config t" -c "router bgp" -c "address-family ipv6 unicast" -c "network 2001:11:11:11:FB01::/80" 2>/dev/null
    sleep 1
    echo "***Experiment complete; this container will exit and the parent script will shut down rtr2 and rtr3"
else
    # Return vmstat to the foreground on rtr2 and rtr3
    fg %1
fi
