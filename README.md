# NSM Kit Automated Installation
#### (Elasticsearch, Kibana, Filebeat, Zeek, and Suricata)

## Table of Contents
1. [Ansible Updates!](#ansible-updates)
1. [Purpose](#purpose)
2. [Description](#description)
3. [Usage](#usage)
    - [Requirements](#requirements)
    - [Installation](#installation)
    - [PCAP](#pcap)
    - [Configuration](#configuration)
4. [Options](#options)
5. [Troubleshooting](#troubleshooting)

## Ansible Updates

This has now been automated with Ansible. The `install.sh` bash script will be left as is for those who do not wish to use Ansible, but all future updates will use Ansible. I will be updating the instructions to use Ansible.

If you would like to still use the old `install.sh` bash script access those instructions [here](https://github.com/jonezy35/NSM-Lite/blob/main/Bash_Script_Instrucitons.md)

## Purpose

This repository contains Ansible playbooks which will automatically deploy a Network Security Monitoring (NSM) kit, which includes Elasticsearch, Kibana, Filebeat, Zeek, and Suricata. The purpose of this project is to simplify the setup process and provide an efficient method for deploying a light weight,  fully functional NSM environment.

These playbooks can be used to setup an NSM kit on a remote machine or locally to setup an NSM kit on your local machine.

Out of the box I've included a few PCAP files which can be used to provide some test logs to work through. If you have a promiscuous interface setup and would prefer to capture from that, I'll provide instructions for that as well.

This could also be used as a good starting point to teach yourself how to setup an NSM kit. By having a known good setup, you can be free to play around, break things, fix them (or scrap it and reinstall), etc. 

## Description

The NSM kit is designed to provide a comprehensive network monitoring solution by integrating the following components:

- <u>[Elasticsearch](https://www.elastic.co/what-is/elasticsearch)</u>

- <u>[Kibana](https://www.elastic.co/what-is/kibana)</u>

- <u>[Filebeat](https://www.elastic.co/beats/filebeat)</u>
- <u>[Zeek](https://zeek.org/)</u>

- <u>[Suricata](https://suricata.io/)</u>

## Usage

### Requirements

This script has been built and tested with Alma Linux 9.1 [Download Alma Linux 9.1 ISO](https://mirrors.almalinux.org/isos/x86_64/9.1.html). If you would like support for another linux distro, open an issue and I will be more than happy to create an install script for said distro.

I have tested this down to 2 CPU's and 4Gb RAM. More is recommended but it will install successfully on that.

It is required that you have sudo permissions and have `git` and Ansible installed. If you don't have git, you can install it with the following command:
`sudo dnf install git -y`

For Ansible:

`sudo yum install ansible -y`

### Installation
Simply run the following commands to get this up and running. The time it takes to install varies depending on your hardware and network speed. Generally the more CPU cores you have the faster the install will be.

```
git clone https://github.com/jonezy35/NSM-Lite.git

cd NSM-Lite
```

You will then need to edit the `inventory.yml` file to specify where you want to install.

If you want to install on a remote machine you will uncomment lines 6-9 and it will look like the following:

If you don't have an ssh key file and don't want to generate one, you can leave line 9 commented out and add `--ask-pass` to every command you run (to authenticate with the remote machine). 

If you wish to test your ansible connection to the remote host, you can use the `ping_test.yml` playbook provided. Simply run:

`ansible-playbook playbooks/ping_test.yml`

If you setup your inventory file correctly, you should get green "ok" response.

If you want to install on your local machine you will uncomment lines 11 and 12 and it will look like the following:

Once you have edited and saved your `inventory.yml` file, you can now install with:

`ansible-playbook playbooks/NSM_install.yml --ask-become`

`--ask-become` will prompt for the sudo password for the machine you are installing the NSM kit on.

The playbook will then prompt you to input your desired password for the `elastic` user and the `kibana_system` user.

Once installed, you can access kibana at http://\<your IP\>:5601

The default login credentials are `elastic` and `<the password you chose for the elastic user>`

The install can take awhile depending on how many CPU cores you have and what other processes you are running. However, the install is completely automated after this step, so feel free to walk away, have some coffee, play some video games. The NSM install will be ready for you when you return.

Once the installation is complete, you can utilize the provided PCAP to create logs for analysis with the following command:

`ansible-playbook playbooks/run_pcap.yml --ask-become`

This playbook will populate your kibana dashboard/ discover with logs from February of 2022 for analysis.
 

## PCAP
There are a few PCAP files available in the `pcap` folder. They are all zipped up, and are password protected with the password `infected`. To unzip them simply run `unzip <pcap>.pcap` I pulled all of these from the [Malware Traffic Analysis](https://www.malware-traffic-analysis.net/training-exercises.html) website. They provide exercises with PCAP and associated answer keys/ quizzes. With this setup, you will be able to pull down any PCAP you want and run it through.

If you want some larger PCAP to run through, I have a .zip file with 17G of PCAP [here](https://drive.google.com/file/d/1B46N6Uqtvz9w-lzwzOV344-ArFPXyAfQ/view?usp=share_link) which is stored in a ~ 4GB zip file. You can download it with gdown and unzip it with tar:
``` 
pip install gdown

gdown --id 1B46N6Uqtvz9w-lzwzOV344-ArFPXyAfQ -O BigPcap.tar.gz

tar xzvf BigPcap.tar.gz
``` 
The pcap is broken up into 15 smaller PCAP files. When you unzip the folder there is a bash script that you can run and it will read all of the PCAP files through zeek and suricata. Because the PCAP is big, the script will take awhile. The data is from 2012, so your logs will be in that time frame.

From the BigPcap directory, run:
```
sudo ./read-pcap.sh
```

The logs for the pcap you run will be dated for when the PCAP happened, not for when you read it in. For example: if you read in PCAP from 2017, the logs will be in 2017, even though it is 2023.

<u>**IMPORTANT:**</u> Before running pcap through zeek or suricata, you have to make sure you're in the correct directory so that filebeat can pull the logs as zeek and suricata store the logs in the current working directory when you use the `-r` option. You also have to give zeek the `json-logs.zeek` path so that zeek writes the logs as json for filebeat to send to elasticsearch (by default zeek stores its logs as tab delimited)

To generate logs for any pcap file you have on your system:

```
cd /opt/zeek/logs/
sudo /./opt/zeek/bin/zeek -r </path/to/pcap> /opt/zeek/share/zeek/policy/tuning/json-logs.zeek
```

```
cd /var/log/suricata/
sudo /./opt/suricata/bin/suricata -r </path/to/pcap>
```
If you have already run pcap and you wish to clear the data before running new pcap, simply clear the logs on the filesystem and then delete the documents from the index: 

```
sudo rm -f /var/log/suricata/eve.json

sudo rm -f /opt/zeek/logs/*.log
```

```
curl --insecure -XGET "https://localhost:9200/_cat/indices?v&pretty" -u elastic:password
```
Now take the index name that is returned and run the following (this may take awhile depending on how many documents you have in your index):

```
curl --insecure -X POST "https://localhost:9200/your_index_name/_delete_by_query?conflicts=proceed&pretty" -H 'Content-Type: application/json' -u elastic:password -d'
{
  "query": {
    "match_all": {}
  }
}
'
```

### Configuration
If you wish to change the passwords after you set them, you can do so with the `elasticsearch-reset-password` utility. Simply run `sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -i` <u>**NOTE**</u>: If you update the default elastic password, you will also have to update it in the filebeat.yml at `/etc/filebeat/filebeat.yml`


## Options
If you want to capture on a promiscuous interface instead of reading PCAP:

Uncomment lines 4 and 5 in the `/etc/zeek/node.cfg` file and replace `eth0` with your promiscuous interface.

Uncomment lines 520-527 in `/etc/suricata/suricata.yaml` and replace `eth0` with your capture interface.

Add `-i <your capture interface>` to line 7 of `/etc/systemd/system/suricata.service` 

You can now start zeek and suricata.

```
sudo systemctl daemon-reload

systemctl start suricata

/./opt/zeek/bin/zeekctl deploy
```

## Troubleshooting

The best way to perform troubleshooting is to run `journalctl -xeu <service> | less` where \<service\> is the service you're troubleshooting.  For example:

```
journalctl -xeu kibana.service | less
```
You can use `SHIFT + G` to jump to the most recent logs.





