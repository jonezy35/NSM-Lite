# NSM Kit Automated Installation
#### (Elasticsearch, Kibana, Filebeat, Zeek, and Suricata)

## Table of Contents
1. [Purpose](#purpose)
2. [Description](#description)
3. [Usage](#usage)
    - [Requirements](#requirements)
    - [Installation](#installation)
    - 

## Purpose

This repository contains an automated installation script for a Network Security Monitoring (NSM) kit, which includes Elasticsearch, Kibana, Filebeat, Zeek, and Suricata. The purpose of this project is to simplify the setup process and provide an efficient method for deploying a light weight,  fully functional NSM environment.

Out of the box I've included a few PCAP files which can be used to provide some test logs to work through. If you have a promiscuous interface setup and would prefer to capture from that, I'll provide instructions for that as well.

This could also be used as a good starting point to teach yourself how to setup an NSM kit. By having a known good NSM kit, you can be free to play around, break things, fix them (or scrap it and reinstall), etc. 

## Description

The NSM kit is designed to provide a comprehensive network monitoring solution by integrating the following components:

- <u>[Elasticsearch](https://www.elastic.co/what-is/elasticsearch)</u>

- <u>[Kibana](https://www.elastic.co/what-is/kibana)</u>

- <u>[Filebeat](https://www.elastic.co/beats/filebeat)</u>
- <u>[Zeek](https://zeek.org/)</u>

- <u>[Suricata](https://suricata.io/)</u>

## Usage

### Requirements

This script has been built and tested with Alma Linux 9.1. If you would like support for another linux distro, open an issue and I will be more than happy to create an install script for said distro. 

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
### Configuration
If you wish to change the default password, you can do so with the `elasticsearch-reset-password` utility. Simply run `sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -i` <u>**NOTE**</u>: If you update the default elastic password, you will also have to update it in the filebeat.yml at `/etc/filebeat/filebeat.yml`

Once the installation is complete, you can utilize the provided PCAP to create logs for analysis.

There are multiple PCAP files available in the `pcap` folder. They are all zipped up, and are password protected with the password `infected`. To unzip them simply run `unzip <pcap>.pcap` I pulled all of these from the [Malware Traffic Analysis](https://www.malware-traffic-analysis.net/training-exercises.html) website. They provide exercises with PCAP and associated answer keys/ quizzes. With this setup, you will be able to pull down any PCAP you want and run it through.

<u>**IMPORTANT:**</u> Before running pcap through zeek or suricata, you have to make sure you're in the correct directory so that filebeat can pull the logs.

```
cd /opt/zeek/logs/
/./opt/zeek/bin/zeek -r </path/to/pcap>
```

```
cd /var/log/suricata/
/./opt/suricata/bin/suricata -r </path/to/pcap>
```
If you have already run pcap and you wish to clear the index before running new pcap through, simply run:

```
curl --insecure -XGET "https://localhost:9200/_cat/indices?v&pretty" -u elastic:password
```
Now take the index name that is returned and run:

```
curl --insecure -X POST "https://localhost:9200/your_index_name/_delete_by_query?conflicts=proceed&pretty" -H 'Content-Type: application/json' -u elastic:password -d'
{
  "query": {
    "match_all": {}
  }
}
'
```
## Options

## Troubleshooting

## License