#!/bin/bash
############################################### To Do: Find Better PCAP ###############################################

echo " "
echo " "
echo -e "This script \033[4mMUST\033[0m be run as root"
echo " "
echo "This script may take a few hours to run."
echo " "
echo "This script will automatically start in 30 seconds..."

countdown=30
while [ $countdown -gt 0 ]; do
  printf "\rCountdown: %2d seconds remaining" $countdown
  sleep 1
  countdown=$((countdown - 1))
done

echo " "
echo "Starting Script..."

# Import RPM GPG key
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org

# Setup extra repositories
dnf config-manager --set-enabled crb
dnf install epel-release -y
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

###Update packages
sudo dnf update -y
###Install needed dependencies
sudo dnf install tar htop git vim wget util-linux-user net-tools unzip expect -y

###Install needed zeek dependencies
sudo dnf install cmake make gcc gcc-c++ flex bison libpcap-devel openssl-devel python3 python3-devel swig zlib-devel -y
###Install needed suricata dependencies
sudo dnf install pcre-devel libyaml-devel jansson-devel lua-devel file-devel nspr-devel nss-devel libcap-ng-devel libmaxminddb-devel lz4-devel rustc cargo python3-pyyaml -y

#Set Elastic Stack Version
ELASTIC_VERSION="8.7.0"

################### Elasticsearch ####################

###Set maxmapcount for Elasticsearch
sudo sysctl -w vm.max_map_count=262144
sudo echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf | sudo sudo sysctl -p

##Install Elasticsearch
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTIC_VERSION}-x86_64.rpm
sudo rpm --install elasticsearch-${ELASTIC_VERSION}-x86_64.rpm

##Copy elasticsearch.yml
mv /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.old
cp elasticsearch.yml /etc/elasticsearch/elasticsearch.yml

sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service

##Start Elasticsearch
sudo systemctl start elasticsearch.service

echo "Changing default elastic password..."
sleep 30

# Set the elastic user password to 'password'
# Run the elasticsearch-reset-password command using expect
/usr/bin/expect <<EOD
spawn sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -i
expect "Please confirm that you would like to continue"
send "y\r"
expect "Please enter new password for user \\[elastic\\]: "
send "password\r"
expect "Please confirm new password for user \\[elastic\\]: "
send "password\r"
expect eof
EOD

# Set the kibana_system password to 'password'
/usr/bin/expect <<EOD
spawn sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u kibana_system -i
expect "Please confirm that you would like to continue"
send "y\r"
expect "Please enter new password for user \\[kibana_system\\]: "
send "password\r"
expect "Please confirm new password for user \\[kibana_system\\]: "
send "password\r"
expect eof
EOD

#################### Kibana #######################

##Install Kibana
wget https://artifacts.elastic.co/downloads/kibana/kibana-${ELASTIC_VERSION}-x86_64.rpm
sudo rpm --install kibana-${ELASTIC_VERSION}-x86_64.rpm

##Copy Kibana.yml
mv /etc/kibana/kibana.yml /etc/kibana/kibana.yml.old
cp kibana.yml /etc/kibana/kibana.yml

# Get the host IP
HOST_IP=$(hostname -I | awk '{print $1}')

# Set the server.host value in the configuration file
CONFIG_FILE="/etc/kibana/kibana.yml"
sed -i "s/^server\.host:.*/server.host: \"$HOST_IP\"/g" "$CONFIG_FILE"

echo "server.host has been set to $HOST_IP in $CONFIG_FILE"

sudo systemctl daemon-reload
sudo systemctl enable kibana.service

# Start Kibana
sudo systemctl start kibana.service

####################### Zeek #######################

##Pull down zeek
git clone --recurse-submodules https://github.com/zeek/zeek
cd zeek

##Install Zeek
./configure --prefix=/opt/zeek --localstatedir=/var/log/zeek --conf-files-dir=/etc/zeek --disable-spicy
make -j$(nproc)
make install
cd ..

##Configure Zeek
sudo mv /etc/zeek/node.cfg /etc/zeek/node.cfg.old
sudo cp node.cfg /etc/zeek/node.cfg 


echo "The default node.cfg file has been created at /etc/zeek/node.cfg"

##Add zeek binaries to the global PATH

#Define the Zeek binary path
zeek_bin_path="/opt/zeek/bin"

#If it's not present, add it

echo "export PATH=\"$zeek_bin_path:\$PATH\"" >> /etc/profile
echo "Zeek binary path added to /etc/profile"
export PATH=/opt/zeek/bin:$PATH
source ~/.bashrc


####################### Suricata ####################### 

##Pull down Suricata
curl -L -O https://www.openinfosecfoundation.org/download/suricata-6.0.10.tar.gz
tar xzvf suricata-6.0.10.tar.gz
cd suricata-6.0.10

##Install Suricata
./configure --prefix=/opt/suricata --enable-lua --enable-geoip --localstatedir=/var/log/suricata  --sysconfdir=/etc --disable-gccmarch-native --enable-profiling --enable-http2-decompression --enable-python --enable-af-packet
make -j$(nproc)
make install-full
cd ..

##Configure Suricata

mv /etc/suricata/suricata.yaml /etc/suricata/suricata.yaml.old
cp suricata.yaml /etc/suricata/suricata.yaml


echo "The default suricata.yaml file has been created at /etc/suricata.yaml"


#Create the systemd service file for Suricata
sudo mv suricata.service /etc/systemd/system/suricata.service

#Reload systemd configuration
systemctl daemon-reload

#Enable Suricata service to start at boot
systemctl enable suricata.service

echo "Suricata systemd service file has been created and enabled."

####################### Filebeat #######################

##Install Filebeat
sudo curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${ELASTIC_VERSION}-x86_64.rpm
sudo rpm -vi filebeat-${ELASTIC_VERSION}-x86_64.rpm

##Copy over filebeat configs
sudo mv /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.old
sudo cp filebeat.yml /etc/filebeat/filebeat.yml

##Set IP for filebeat to connect to
FILEBEAT_CONFIG_FILE="/etc/filebeat/filebeat.yml"
sed -i "s/^setup\.kibana\.host:.*/setup.kibana.host: \"$HOST_IP:5601\"/g" "$FILEBEAT_CONFIG_FILE"

echo "setup.kibana.host has been set to $HOST_IP:5601 in $FILEBEAT_CONFIG_FILE"

sudo mv /etc/filebeat/modules.d/zeek.yml.disabled /etc/filebeat/modules.d/zeek.yml.disabled.old
sudo cp zeek.yml.disabled /etc/filebeat/modules.d/zeek.yml.disabled 

sudo mv /etc/filebeat/modules.d/suricata.yml.disabled /etc/filebeat/modules.d/suricata.yml.disabled.old
sudo cp suricata.yml.disabled /etc/filebeat/modules.d/suricata.yml.disabled


####################### Configure Firewall Rules #######################

sudo firewall-cmd --add-port 5601/tcp --permanent
sudo firewall-cmd --add-port 9200/tcp --permanent
sudo firewall-cmd --reload 

###Start Services###

echo " "
echo " "
echo "The sensor is now installed and configured"
echo " "
echo "Starting Services in 10 seconds..."
countdown=10
while [ $countdown -gt 0 ]; do
  printf "\rCountdown: %2d seconds remaining" $countdown
  sleep 1
  countdown=$((countdown - 1))
done

sudo filebeat modules enable suricata zeek
sudo filebeat setup -e
sudo systemctl start filebeat

####################### Comments #######################

echo "The default node.cfg file has been created at /etc/zeek/node.cfg"
echo "zeek has been installed at /opt/zeek (which has been added to your PATH variable). You can interact with zeek via zeekctl."
echo " "
echo "The default suricata.yaml file has been created at /etc/suricata.yaml"
echo "A systemd file has been created for suricata. You can now interact with suricata via systemctl"
echo " "


############### URL for more PCAP to analyze ####################
#### https://www.malware-traffic-analysis.net/training-exercises.html

#cd /opt/zeek/logs/
#/./opt/zeek/bin/zeek -r /etc/suricata/2023-03-Unit42-Wireshark-quiz.pcap
#cd /var/log/suricata/
#/./opt/suricata/bin/suricata -r /etc/suricata/2023-03-Unit42-Wireshark-quiz.pcap 