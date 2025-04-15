#!/bin/bash

# Make sure all images are built
docker compose build rtr1 verify

# Start the routing infrastructure
echo "Starting routing infrastructure in background"
docker compose up -d rtr1 rtr2 rtr3

# Test for network convergence using ping from rtr1
echo "Checking connectivity from rtr1"
docker compose exec rtr1 /opt/connectivity-check.sh

# Network is converged
# Start instrumentation and launch experiment
echo "Configurting instrumentation on all speakers (rtr2 and rtr3 in background)"
docker compose exec -d rtr2 /opt/experiment.sh
docker compose exec -d rtr3 /opt/experiment.sh
docker compose exec rtr1 /opt/experiment.sh # start this one last so it can control execution

# Tear down experiment environment
docker compose stop -t0

# Combine the disparate logfiles to one, ordered by monotonic timestamp
echo "Compiling logfiles..."
docker compose run verify logonly
docker compose down