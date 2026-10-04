#!/bin/bash
compile(){
   make
   sudo make install
}
sudo apt-get update && sudo apt-get dist-upgrade -y
sudo apt install git build-essential libpcap-dev libpcre2-dev libnet1-dev zlib1g-dev luajit hwloc libdumbnet-dev bison flex liblzma-dev openssl libssl-dev pkg-config libhwloc-dev cmake cpputest libsqlite3-dev uuid-dev libcmocka-dev libnetfilter-queue-dev libmnl-dev autotools-dev libluajit-5.1-dev libunwind-dev libfl-dev -y
git clone https://github.com/snort3/libdaq.git
cd libdaq
./bootstrap
./configure
compile
cd ..
wget https://github.com/gperftools/gperftools/releases/download/gperftools-2.9.1/gperftools-2.9.1.tar.gz
tar xzf gperftools-2.9.1.tar.gz
cd gperftools-2.9.1/
./configure
compile
cd ..
wget https://github.com/snort3/snort3/archive/refs/heads/master.zip
unzip master.zip
cd snort3-master
./configure_cmake.sh --prefix=/usr/local --enable-tcmalloc
cd build
compile
sudo ldconfig
snort -V                                                                                           
LISTENING_INTERFACE=$(ip route | grep default | awk '{print $5}')
sudo ip link set dev "$LISTENING_INTERFACE" promisc on
sudo ethtool -K "$LISTENING_INTERFACE" gro off lro off
cat <<EOL | sudo tee /etc/systemd/system/snort3-nic.service 
> [Unit]
Description=Set Snort 3 NIC in promiscuous mode and Disable GRO, LRO on boot
After=network.target
[Service]
Type=oneshot
Environment=LISTENING_INTERFACE=$(ip route | grep default | awk '{print $5}')
ExecStart=/usr/sbin/ip link set dev \${LISTENING_INTERFACE} promisc on
ExecStart=/usr/sbin/ethtool -K \${LISTENING_INTERFACE} gro off lro off
TimeoutStartSec=0
RemainAfterExit=yes
[Install]
WantedBy=default.target
EOL
sudo systemctl daemon-reload
sudo systemctl enable --now snort3-nic.service
sudo service snort3-nic status
