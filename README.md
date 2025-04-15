# Dissertation

The source code in this repository represents the environment used to test performance impacts when introducing singatures to be used in de-facto network indentification within FRR. The two referenced projects are `frrouting/frr` and `IurmanJ/ebpf-ipv6-exthdr-injection`.

## Environment Setup
To repeat this experiment, configure Linux on a VM or physical machine. For the study, Ubuntu 24.04 was used. Then, install Docker. This can be done easily with `curl -fsSL get.docker.com | sudo bash`, but understand the risks that come with running such a command.

## Pre-Test
The modifications for the pre-test exist entirely in the [normal](normal) directory. In the pre-test, the only change to FRR is to adding timestamps when certain events occur. To run this experiment and capture all of the requisite datapoints, run the script `./run_normal.sh`. You may be prompted to allow non-root access to eBPF. The command is provided by the script if it's necessary.

## Post-Test
The post-test adds additional elements to create signatures for network layer reachability information and embed such signatures in the IPv6 Destination Options header using eBPF. To run this test, run the script `./run_signatures.sh`. **Note** the private key used for signing each message is *not* included in the repository, but is available upon request if necessary for your testing. If a private key isn't in the signature directory at the time the run_signatures.sh script is ran, it will be created.