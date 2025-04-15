from scapy.all import rdpcap, TCP, IPv6ExtHdrDestOpt, IPv6
from socket import AF_INET6, htons
from scapy.contrib.bgp import BGPUpdate
from nacl.signing import VerifyKey
from nacl.encoding import HexEncoder, RawEncoder
from scapy.pton_ntop import inet_pton
import struct
from binascii import hexlify
from sys import argv, exit
import glob
from os import path
from datetime import datetime

res = {"verified": [], "unverified": []}

# check for logonly option
if len(argv) != 2:
    # Find the most recent pcap in the rtr2 directory
    file = max(glob.glob("/cap/as2000/*.pcap"), key=path.getmtime)
    print(f"Opening {file} for analysis...")
    cap = rdpcap(file)

    for p in cap:
        # only show packets originating from router 1 that are BGP and have the IPv6 Destination Options Extension Header
        if IPv6 in p and p[IPv6].src == "2001:11:11:11::10" and TCP in p and p[TCP].sport == 179 and BGPUpdate in p and IPv6ExtHdrDestOpt in p: 
            # Parse key and signature from header
            siginfo = p[IPv6][IPv6ExtHdrDestOpt].options[0].optdata
            sig = siginfo[:64]
            key = siginfo[64:]
            
            # Iterate over BGP path attributes until we find MP_NLRI, and then parse out the IP and prefix
            for pa in p[BGPUpdate].path_attr:
                if pa.type_code == 14: # MP_NLRI
                    # The prefix is in network byte order so fix that up
                    mask = struct.pack('<H', int(pa.attribute.nlri[0].prefix.split('/')[1]))
                    addr = pa.attribute.nlri[0].prefix.split('/')[0]
                    # convert the IP address to bytes
                    bin = inet_pton(AF_INET6, addr)

                    # Combine the prefix and address as it is on rtr1
                    prefixstruct = mask + bin

                    # Configure library to verify message
                    vk = VerifyKey(key, RawEncoder)
                    try:
                        vk.verify(prefixstruct, sig)
                        res['verified'].append(pa.attribute.nlri[0].prefix)
                    except:
                        res['unverified'].append(pa.attribute.nlri[0].prefix)

    print(f"Verified {len(res['verified'])} prefixes.")
    if len(res['unverified']) > 0:
        print(f"{len(res['unverified'])} unverified prefixes to investigate: {', '.join(res['unverified'])}")

    if len(res['verified']) == 1: # exit here in the event we're just testing to see if eBPF is working
        exit(0)

if len(res['verified']) > 0 or len(argv) == 2: # in this case, we have completed the experiment and would like to compile the log
    # 1 - Parse each cap file into a large list
    r1 = open("/cap/as1000/log.txt", "r").read()
    r1 = [x.split(',') for x in r1[r1.rfind("---START"):].split('\n')][1:-1]
    r2 = open("/cap/as2000/log.txt", "r").read()
    r2 = [x.split(',') for x in r2[r2.rfind("---START"):].split('\n')][1:-1]
    r3 = open("/cap/as3000/log.txt", "r").read()
    r3 = [x.split(',') for x in r3[r3.rfind("---START"):].split('\n')][1:-1]

    # 2 - create a master list of all events, but include system name
    master = []
    for r in r1:
        ts = int(r[2]) + (int(r[3]) / 1000000000)
        master.append(["rtr1", r[0], r[1], ts])
    for r in r2:
        ts = int(r[2]) + (int(r[3]) / 1000000000)
        master.append(["rtr2", r[0], r[1], ts])
    for r in r3:
        ts = int(r[2]) + (int(r[3]) / 1000000000)
        master.append(["rtr3", r[0], r[1], ts])
    
    # 3 - sort the list base on the timestamp
    master.sort(key=lambda x: x[3])

    # 4 - write out the master list
    with open(f"/cap/compiled_{datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}.txt", "w") as f:
        for l in master:
            f.write(f"{l[0]},{l[1]},{l[2]},{l[3]}\n")

    exit(0)
else:
    exit(1) # we didn't find any verifiable prefixes - we must restart

