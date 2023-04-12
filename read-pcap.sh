#!/bin/bash

# Iterate through pcap files in the current directory
for pcap_file in ./*.pcap; do
    # Run Zeek on the pcap file
    echo "Running Zeek on $pcap_file..."
    sudo /./opt/zeek/bin/zeek -r "$pcap_file" /opt/zeek/share/zeek/policy/tuning/json-logs.zeek
    mv *.log /opt/zeek/logs/

    # Run Suricata on the pcap file
    echo "Running Suricata on $pcap_file..."
    sudo /./opt/suricata/bin/suricata -r "$pcap_file"
    mv eve.json /var/log/suricata
done

echo "Processing complete."
