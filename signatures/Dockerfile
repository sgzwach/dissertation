FROM debian:bookworm-slim

# Build and Install per: https://docs.frrouting.org/projects/dev-guide/en/latest/building-frr-for-debian12.html#install-required-packages

# Pre-reqs
RUN apt-get update && apt-get install -y git autoconf automake libtool make \
libprotobuf-c-dev protobuf-c-compiler build-essential \
python3-dev python3-pytest python3-sphinx libjson-c-dev \
libelf-dev libreadline-dev cmake libcap-dev bison flex \
pkg-config texinfo gdb libgrpc-dev python3-grpc-tools \
iputils-ping tcpdump iproute2 libssl-dev clang binutils-dev llvm

# libyang steps from frr build guide
RUN apt-get install -y libpcre2-dev cmake
WORKDIR /src
RUN git clone https://github.com/CESNET/libyang.git
WORKDIR /src/libyang
RUN git checkout v2.1.128
RUN mkdir build
WORKDIR /src/libyang/build
RUN cmake --install-prefix /usr -D CMAKE_BUILD_TYPE:String="Release" ..
RUN make
RUN make install

# frr users/groups
RUN addgroup --system --gid 92 frr
RUN addgroup --system --gid 85 frrvty
RUN usermod -a -G frrvty root

# Pull ebpf items
WORKDIR /src
RUN git clone https://github.com/IurmanJ/ebpf-ipv6-exthdr-injection.git

# move into ebpf dev directory and remove sudo from makefile
WORKDIR /src/ebpf-ipv6-exthdr-injection
RUN sed -i s/sudo//g Makefile

# build ebpf deps first so FRR can use them
RUN make deps

# Copy custom code; build
COPY ebpf_patches/*.patch .
RUN for f in $(ls *.patch); do patch < $f; done
RUN make build

# build frr
WORKDIR /src
RUN git clone https://github.com/frrouting/frr.git
WORKDIR /src/frr
RUN git checkout frr-10.1
RUN ./bootstrap.sh
# COPY Makefile.am .
ENV LIBS="-lbpf -lcrypto -lelf"
ENV LDFLAGS="-L/src/ebpf-ipv6-exthdr-injection/build/usr/lib64 -L/usr/lib64"
ENV CPPFLAGS="-I/src/ebpf-ipv6-exthdr-injection/build/usr/include -I/src/ebpf-ipv6-exthdr-injection/"
RUN ./configure \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --sbindir=/usr/lib/frr \
    --enable-multipath=64 \
    --enable-user=root \
    --enable-group=root \
    --enable-vty-group=frrvty \
    --enable-configfile-mask=0640 \
    --enable-logfile-mask=0640 \
    --enable-fpm \
    --with-pkg-git-version \
    --disable-doc --disable-ripd --disable-ripngd --disable-ospfd --disable-ospf6d --disable-ldpd \
    --disable-nhrpd --disable-eigrpd --disable-babeld --disable-isisd --disable-pimd --disable-pim6d \
    --disable-pbrd --disable-fabricd --disable-vrrpd --disable-pathd --disable-ospfapi --disable-ospfclient --disable-bfdd

# Patch frr with signatures and timing
COPY frr_patches/*.c /src/frr/bgpd/
COPY frr_patches/*.h /src/frr/bgpd/
COPY frr_patches/*.patch /src/frr/bgpd/

# Fetch patched tc_ipv6_eh header from other project
RUN cp /src/ebpf-ipv6-exthdr-injection/tc_ipv6_eh.h /src/frr/bgpd/

# Apply patches
WORKDIR /src/frr/bgpd/
RUN for f in $(ls *.patch); do patch < $f; done

# Build ebpf injection using tc egress filtering
WORKDIR /src/ebpf-ipv6-exthdr-injection/deps/libbpf/src
RUN make
RUN make install
WORKDIR /src/frr
RUN make
RUN make install

# setup daemon file
RUN mkdir /etc/frr
RUN cp /src/frr/tools/etc/frr/daemons /etc/frr/daemons
RUN sed -i s/bgpd\=no/bgpd\=yes/g /etc/frr/daemons

# fix shared objects
RUN ldconfig

# run directory 
RUN mkdir /var/run/frr

# filter startup
RUN mkdir /crypto
COPY key.txt /crypto/
COPY key.txt .

# Add bpftool to path
ENV PATH="$PATH:/src/ebpf-ipv6-exthdr-injection/deps/bpftool/src"

# add experiment start
WORKDIR /opt
ADD scripts .
ENTRYPOINT ["/opt/entrypoint.sh"]