#!/bin/bash

# Will need to make sure this is taken care of at some point
unprivbpf=$(sysctl -n kernel.unprivileged_bpf_disabled)
if [ $unprivbpf != 0 ]; then
    echo "For this experiment to function in its current state, unprivileged_bpf_disabled must be allowed"
    echo "You must run this command, then re-run the script: sudo sysctl kernel.unprivileged_bpf_disabled=0"
    exit 1
fi

# Make sure key exists (request key from author if necessary for your testing; this generates a new key if one isn't present)
if [ ! -f "./signatures/key.txt" ]; then
    docker run alpine/openssl genpkey -algorithm ed25519 -outform PEM > signatures/key.txt
fi

# Make sure all images are built
docker compose build rtr1 rtr1_signed verify

while true; do
    # Start the routing infrastructure
    echo "Starting routing infrastructure in background"
    docker compose up -d rtr1_signed rtr2 rtr3

    # Test for network convergence using ping from rtr1
    echo "Checking connectivity from rtr1"
    docker compose exec rtr1_signed /opt/connectivity-check.sh

    # Network is converged; enable eBPF on rtr1 and test with pcap from rtr2
    docker compose exec -d rtr2 /opt/enable-ebpf.sh # on rtr2 this just creates a small pcap
    docker compose exec rtr1_signed /opt/enable-ebpf.sh
    docker compose exec rtr2 pkill tcpdump
    docker compose up --exit-code-from verify verify
    if [ $? -ne 0 ]; then # handle the case where ebpf doesn't work
        echo "Something isn't working with injection; restarting routing infrastructure..."
        docker compose down -t0
        continue
    fi

    # Start instrumentation and launch experiment
    echo "Configurting instrumentation on all speakers (rtr2 and rtr3 in background)"
    docker compose exec -d rtr2 /opt/experiment.sh
    docker compose exec -d rtr3 /opt/experiment.sh
    docker compose exec rtr1_signed /opt/experiment.sh # start this one last so it can control execution

    # Tear down experiment environment
    docker compose stop -t0

    # Verify that signatures and keys are valid for the prefixes sent following the experiment
    echo "Running verification script, output should be 1001 verified prefixes"
    docker compose up --exit-code-from verify verify
    if [ $? -eq 0 ]; then # verify should return 0 if any verifiable prefixes were found
        # Final clean up
        docker compose down
        break
    fi
done