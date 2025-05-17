#!/bin/bash

# Master node'dan join komutunu al
scp -o StrictHostKeyChecking=no vagrant@192.168.56.10:/home/vagrant/join.sh /home/vagrant/join.sh
chmod +x /home/vagrant/join.sh

# Cluster'a katıl
/home/vagrant/join.sh
