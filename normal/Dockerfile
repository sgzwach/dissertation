FROM debian:bookworm-slim

# Build and Install per: https://docs.frrouting.org/projects/dev-guide/en/latest/building-frr-for-debian12.html#install-required-packages

# Pre-reqs (some of these are used in the post-test version, but included in both images)
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

# build frr
WORKDIR /src
RUN git clone https://github.com/frrouting/frr.git
WORKDIR /src/frr
RUN git checkout frr-10.1
RUN ./bootstrap.sh
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

# Copy over our patched and new files
COPY frr_patches/*.c /src/frr/bgpd/
COPY frr_patches/*.h /src/frr/bgpd/
COPY frr_patches/*.patch /src/frr/bgpd/

# Apply patches
WORKDIR /src/frr/bgpd/
RUN for f in $(ls *.patch); do patch < $f; done

# # Build ebpf injection using tc egress filtering
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

# add experiment start
WORKDIR /opt
ADD scripts .
ENTRYPOINT ["/opt/entrypoint.sh"]