#!/bin/bash

# Start FRR on each container
# Originated from: https://github.com/FRRouting/frr/blob/stable/10.1/docker/debian/docker-start
source /usr/lib/frr/frrcommon.sh
/usr/lib/frr/watchfrr $(daemon_list)