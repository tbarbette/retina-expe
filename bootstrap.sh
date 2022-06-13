#!/bin/bash
source /etc/lsb-release
if [ -z "$DISTRIB_RELEASE" ] ; then
	echo "You need Ubuntu (preferably 20.04)"
	exit 1
fi

#Installing all dependencies at once
sudo apt-get -y install python3 python3-pip build-essential meson pkg-config libnuma-dev python3-pyelftools libpcap-dev libclang-dev libyaml-dev  libpcre3 libpcre3-dbg libpcre3-dev libpcap-dev   \
                libnet1-dev libyaml-0-2 libyaml-dev pkg-config zlib1g zlib1g-dev \
                libcap-ng-dev libcap-ng0 make libmagic-dev         \
                libnss3-dev libgeoip-dev liblua5.1-dev libhiredis-dev libevent-dev libjansson-dev liblz4-dev libpcre2-dev
OFED=MLNX_OFED_LINUX-5.4-1.0.3.0-ubuntu${DISTRIB_RELEASE}-x86_64
wget http://www.mellanox.com/downloads/ofed/MLNX_OFED-5.4-1.0.3.0/${OFED}.tgz
tar xvf ${OFED}.tgz
pushd ${OFED}
sudo ./mlnxofedinstall --dpdk --upstream-libs --with-mft --with-kernel-mft --without-fw-update -q
rm -f ${OFED}.tgz

popd
wget http://fast.dpdk.org/rel/dpdk-21.08.tar.xz
tar xJf dpdk-21.08.tar.xz
rm -f dpdk-21.08.tar.xz
export DPDK_PATH=$(pwd)/dpdk-21.08
export LD_LIBRARY_PATH=$DPDK_PATH/lib/x86_64-linux-gnu
export PKG_CONFIG_PATH=$LD_LIBRARY_PATH/pkgconfig

pushd $DPDK_PATH
meson --prefix=$DPDK_PATH build
cd build
sudo ninja install
sudo ldconfig
ninja clean
popd 

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 

echo "export PATH=\$PATH:/users/TomB/.local/bin/meson/" >> /local/env
echo "export RTE_SDK=$DPDK_PATH" >> /local/env
echo "export DPDK_PATH=$DPDK_PATH" >> /local/env
echo "export PKG_CONFIG_PATH=$DPDK_PATH/lib/x86_64-linux-gnu/pkgconfig/" >> /local/env
echo "source $HOME/.cargo/env" >> /local/env


source /local/env

git clone http://github.com/stanford-esrg/retina.git
pushd retina
cargo build --release
popd

cargo install --force cbindgen
git clone https://github.com/OISF/suricata.git
pushd suricata
#Build libhtp
git clone https://github.com/OISF/libhtp
pushd libhtp
./autogen.sh && ./configure && make && sudo make install
popd
./autogen.sh
./configure --enable-dpdk
make
sudo make install
popd

echo "Bootstrap finished!"
