#!/bin/bash

function addline() {
	line=$1
	file=$2
	sudo grep "$line" $file &> /dev/null
	if [ $? != 0 ] ; then
		sudo su -c "echo \"$line\" >> $file"
	fi
}

sudo apt-get update
sudo apt-get -y install vim git zsh build-essential python3 python3-pip ninja-build libnuma-dev htop libmicrohttpd-dev linux-tools-$(uname -r)
sudo python3 -m pip install --upgrade pip
sudo python3 -m pip install --upgrade meson==0.59.4 npf
export PATH=$PATH:/users/$USER/.local/bin/meson/
sudo mkdir -p /mnt/huge
sudo mkdir -p /mnt/huge_1G
(sudo mount | grep hugetlbfs) > /dev/null || sudo mount -t hugetlbfs nodev /mnt/huge
addline "nodev /mnt/huge hugetlbfs       defaults        0 0" /etc/fstab
echo 4096 | sudo tee /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages
addline "vm.nr_hugepages=4096" /etc/sysctl.conf

#Use a mem tmpfs
sudo mount -t tmpfs -o size=8G tmpfs /tmp

sudo chmod o-w -R /local 
sudo chmod o-w -R /mydata


USERS="root `ls /users`"
for user in $USERS; do
	sudo chsh -s /bin/bash $user
	echo "source /local/env" | sudo tee -a /users/$user/.bashrc &> /dev/null
done


HOSTNAME=$(hostname)
for i in $(seq 0 2) ; do
	ip=$(getent hosts node-${i}.${HOSTNAME#*.} | awk "{print $1}")
       addline "${ip}	node-$i-ctrl" /etc/hosts
done

ln -s $(dirname $0) /local/retina-expe
ln -s $(dirname $0) /mydata/retina-expe

cd $(dirname $0)
chmod +x bootstrap.sh
./bootstrap.sh

