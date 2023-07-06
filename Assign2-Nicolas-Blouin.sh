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

dpkg -s openssh-server &> /dev/null
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


if [[ $(ufw status | grep -w "Status: active") ]]; then
  echo "UFW firewall is already enabled."
  #Will add rules anyways even if the firewall is active
  echo "Adding rules"
 
  ufw allow 22

  ufw allow 80

  ufw allow 443

  ufw allow 3128

  ufw reload

#when the firewall is not on run the else and enable it and apply rules to allow my listed ports
else

  echo "Enabling UFW firewall..."

  ufw enable

  ufw allow 22

  ufw allow 80

  ufw allow 443

  ufw allow 3128

  ufw reload

  echo "Firewall turned on and setup was successful!"
fi

