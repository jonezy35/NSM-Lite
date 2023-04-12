# NSM Kit Automated Installation
#### (Elasticsearch, Kibana, Filebeat, Zeek, and Suricata)

## Table of Contents
1. [Purpose](#purpose)
2. [Description](#description)
3. [Usage](#usage)
    - [Requirements](#requirements)
    - [Installation](#installation)
    - [PCAP](#pcap)
    - [Configuration](#configuration)
4. [Options](#options)
5. [Troubleshooting](#troubleshooting)

## Purpose

This repository contains an automated installation script for a Network Security Monitoring (NSM) kit, which includes Elasticsearch, Kibana, Filebeat, Zeek, and Suricata. The purpose of this project is to simplify the setup process and provide an efficient method for deploying a light weight,  fully functional NSM environment.

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

I have tested this down to 2 CPU's and 2Gb RAM. More is recommended but it will install successfully on that.

It is required that you have sudo permissions and have `git` installed. If you don't have git, you can install it with the following command
`sudo dnf install git -y`

### Installation
Simply run the following commands to get this up and running. The time it takes to install varies depending on your hardware and network speed. Generally the more CPU cores you have the faster the install will be.

```
git clone https://github.com/jonezy35/NSM-Lite.git

cd NSM-Lite

sudo ./Install.sh
```
Once installed, you can access kibana at http://\<your IP\>:5601

The default login credentials are `elastic` and `password`

Once the installation is complete, you can utilize the provided PCAP to create logs for analysis.
 

## PCAP
There are a few PCAP files available in the `pcap` folder. They are all zipped up, and are password protected with the password `infected`. To unzip them simply run `unzip <pcap>.pcap` I pulled all of these from the [Malware Traffic Analysis](https://www.malware-traffic-analysis.net/training-exercises.html) website. They provide exercises with PCAP and associated answer keys/ quizzes. With this setup, you will be able to pull down any PCAP you want and run it through.

If you want some larger PCAP to run through, I have a .zip file with 17G of PCAP [here](https://drive.google.com/file/d/1d6QXF0uk1ZiJKfaqwy4SjfvuyVUGrCte/view?usp=share_link) which is stored in a ~ 3GB zip file. You can download it with gdown and unzip it with tar:
``` 
pip install gdown

gdown --id 1DYR3jWKJcksl20_8dqBwo0qWBXIqm594 -O BigPcap.tar.gz

tar xzvf BigPcap.tar.gz
``` 
The pcap is broken up into 15 smaller PCAP files. When you unzip the folder there is a bash script that you can run and it will read all of the PCAP files through zeek and suricata. Because the PCAP is big, the script will take awhile. The data is from 2012, so your logs will be in that time frame.

From the BigPcap directory, run:
```
sudo ./read-pcap.sh
```

The logs for the pcap you run will be dated for when the PCAP happened, not for when you read it in. For example: if you read in PCAP from 2017, the logs will be in 2017, even though it is 2023.

<u>**IMPORTANT:**</u> Before running pcap through zeek or suricata, you have to make sure you're in the correct directory so that filebeat can pull the logs as zeek and suricata store the logs in the current working directory when you use the `-r` option. You also have to give zeek the `json-logs.zeek` path so that zeek writes the logs as json for filebeat to send to elasticsearch (by default zeek stores its logs as tab delimited)

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
sudo rm /var/log/suricata/eve.json

sudo rm /opt/zeek/logs/*.log
```

```
curl --insecure -XGET "https://localhost:9200/_cat/indices?v&pretty" -u elastic:password
```
Now take the index name that is returned and run the following (this may take awhile depending on how many documenst you have in your index):

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
If you wish to change the default password, you can do so with the `elasticsearch-reset-password` utility. Simply run `sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -i` <u>**NOTE**</u>: If you update the default elastic password, you will also have to update it in the filebeat.yml at `/etc/filebeat/filebeat.yml`


## Options
If you want to capture on a promiscuous interface instead of reading PCAP:

Uncomment lines 4 and 5 in the `/etc/zeek/node.cfg` file and replace `eth0` with your promiscuous interface.

Uncomment lines 520-527 in `/etc/suricata/suricata.yaml` and replace `eth0` with your capture interface.

Add `-i <your capture interface>` to line 7 of `/etc/systemd/system/suricata.service` 

You can now start zeek and suricata.

```
sudo systemctl daemon-reload

systemctl start suricata

/./opt/zeek/bin/zeek deploy
```

## Troubleshooting

The best way to perform troubleshooting is to run `journalctl -xeu <service> | less` where \<service\> is the service you're troubleshooting.  For example:

```
journalctl -xeu kibana.service | less
```
You can use `SHIFT + G` to jump to the most recent logs.





