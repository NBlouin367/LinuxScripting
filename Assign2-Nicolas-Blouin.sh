#!/bin/bash

#Assignment 2 - System Modification Assignment
#Name: Nicolas Blouin
#Student ID: 200410446
#Course Code: COMP2137

#Description
if [[ $(hostname) != "autosrv" ]]; then
    echo "Updating the hostname"
    echo "autosrv" > /etc/hostname
    hostnamectl set-hostname autosrv
    
    if [ $? -eq 0 ]; then
       echo "Hostname has been changed!"
    fi

    if [ $? -ne 0 ]; then
       echo "Hostname change failed!"
    fi

else
    echo "Hostname is already set correctly"
fi

dpkg -s openssh-server 
if [ $? -ne 0 ]; then
    echo "Installing SSH server..."
    sudo apt install -y openssh-server
    # Configure SSH server
    sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo sed -i 's/PubkeyAuthentication no/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    sudo systemctl restart sshd
else
    echo "SSH server is already installed."
fi

dpkg -s apache2 &> /dev/null
if [ $? -ne 0 ]; then
    echo "Installing Apache2 web server..."
    sudo apt install -y apache2
    # Configure Apache2
    sudo a2enmod ssl
    sudo systemctl restart apache2
else
    echo "Apache2 web server is already installed."
fi

dpkg -s squid &> /dev/null
if [ $? -ne 0 ]; then
    echo "Installing Squid web proxy..."
    sudo apt install -y squid
    # Configure Squid
    sudo sed -i 's/http_port 3128/http_port 3128/' /etc/squid/squid.conf
    sudo systemctl restart squid
else
    echo "Squid web proxy is already installed."
fi


interface_name=$(ip route | awk '/default/ {print $5}')

config="
network:
  version: 2
  renderer: networkd
  ethernets:
    $interface_name:
      addresses: [192.168.16.21/24]
      routes: 
        - to: 0.0.0.0/0
          via: 192.168.16.1
      nameservers:
        addresses: [192.168.16.1]
        search: [home.arpa, localdomain]"

new_netplan="/etc/netplan/new_netplan_config.yaml"

echo "$config" | sudo tee "$new_netplan" > /dev/null

sudo netplan apply

if [ $? -eq 0 ]; then
    echo "Netplan configuration was applied!"
fi

