#!/bin/bash

# This script checks connectivity across docker containers used in the experiment before starting the experiment
res=4
while [ $res -gt 0 ] # do not continue until all hosts are reachable
do
    echo "$(hostname): Waiting for all speakers to be reachable..."
    sleep 1
    res=0
    ping 2001:11:11:11::10 -c1 > /dev/null 2>&1
    ((res+=$?))
    ping 2001:11:11:11::20 -c1 > /dev/null 2>&1
    ((res+=$?))
    ping 2001:12:12:12::20 -c1 > /dev/null 2>&1
    ((res+=$?))
    ping 2001:12:12:12::30 -c1 > /dev/null 2>&1
    ((res+=$?))
done

echo "$(hostname): All hosts are reachable"