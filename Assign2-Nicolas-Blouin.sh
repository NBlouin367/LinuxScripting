#!/bin/bash

#Assignment 2 - System Modification Assignment
#Name: Nicolas Blouin
#Student ID: 200410446
#Course Code: COMP2137

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

