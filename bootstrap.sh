#!/bin/bash
source /etc/lsb-release
if [ -z "$DISTRIB_RELEASE" ] ; then
	echo "You need Ubuntu (preferably 20.04)"
	exit 1
fi
sudo apt-get -y install python3 python3-pip build-essential meson pkg-config libnuma-dev python3-pyelftools libpcap-dev libclang-dev
OFED=MLNX_OFED_LINUX-5.4-1.0.3.0-ubuntu${DISTRIB_RELEASE}-x86_64
wget http://www.mellanox.com/downloads/ofed/MLNX_OFED-5.4-1.0.3.0/${OFED}.tgz
tar xvf ${OFED}.tgz
pushd ${OFED}
sudo ./mlnxofedinstall --dpdk --upstream-libs --with-mft --with-kernel-mft --without-fw-update -q
#ibv_devinfo    # verify firmware is correct, set to Ethernet

popd
wget http://fast.dpdk.org/rel/dpdk-21.08.tar.xz
tar xJf dpdk-21.08.tar.xz
export DPDK_PATH=$(pwd)/dpdk-21.08
export LD_LIBRARY_PATH=$DPDK_PATH/lib/x86_64-linux-gnu
export PKG_CONFIG_PATH=$LD_LIBRARY_PATH/pkgconfig

pushd $DPDK_PATH
meson --prefix=$DPDK_PATH build
cd build
sudo ninja install
sudo ldconfig
popd 

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

echo "export PATH=\$PATH:/users/TomB/.local/bin/meson/" >> ~/.bashrc
echo "export RTE_SDK=/users/TomB/workspace/dpdk/" >> ~/.bashrc
echo "export DPDK_PATH=/users/TomB/workspace/dpdk/" >> ~/.bashrc

source $HOME/.cargo/env

git clone git@github.com:stanford-esrg/retina.git
pushd retina
cargo build --release

popd

