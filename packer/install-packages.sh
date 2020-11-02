#!/bin/bash

sudo apt -y update
# INTSTALL JENKINS AND JAVA
echo "----------- Install Java JDK 8 ----------"
sudo apt install -y openjdk-8-jdk
# INSTALL DEPENDENCIES
sudo apt -y install awscli
sudo apt -y  install xmlstarlet
sudo apt -y install docker.io
sudo apt install -y python
sudo apt -y update
sudo apt install -y  python-pip
sudo pip install bcrypt

sudo usermod -aG docker ubuntu
sudo systemctl start docker
sudo chmod 666 /var/run/docker.sock
sudo chown root:docker /var/run/docker.sock
