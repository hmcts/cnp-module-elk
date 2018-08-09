#!/bin/bash

# Get the PGP Key
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-6.x.list

apt-get update
if [ -z "$LOGSTASH_VERSION" ]; then
    echo "Installing the latest Elasticsearch version"
    apt-get install logstash
else
    echo "Installing Logstash version $LOGSTASH_VERSION"
    apt-get install logstash=$LOGSTASH_VERSION
fi

systemctl status logstash

mv logstash.conf /usr/share/logstash/logstash.yml