#!/bin/bash

#Assignment 3 - Automated Configuration Assignment
#Name: Nicolas Blouin
#Student ID: 200410446
#Course Code: COMP2137
#Due Date: Wednesday, August 4th, 2023.


if [ "$EUID" -ne 0 ]; then

  echo "This script must be run as sudo/root. Either be root user or use sudo with the command to ensure it runs correctly." >&2

  exit 1

fi

target1_management="remoteadmin@172.16.1.0"

ssh "$target1_management" << EOF

echo "Going to configure target1-mgmt (172.16.1.10)"

if [[ $(hostname) != "loghost" ]]; then

    echo "Updating the system name to loghost"
    echo "loghost" > /etc/hostname
    hostnamectl set-hostname loghost

    #if the exit status is 0, the hostname change was successful then display it worked

    if [ $? -eq 0 ]; then

        echo "Hostname has been changed!"

    #By using an else I can make sure I handle errors. When the condition of my previous if statement is not met the else will run.
    #Since my if statement above was checking if exit status of the hostnamectl command was equal to 0 meaning success
    #then any failures/outcomes would result in this else being executed. I display an error and then using exit 1
    #I terminate the script.

    else

        echo "Attempt to change the hostname failed. Exiting Script"
        exit 1

    fi

#if the if statement condition does not execute then run the else
#it will just display some text saying the host name is already set up.

else

    echo "Hostname is already set correctly."

fi

#Setting IP address on on management 1

ip addr add 192.168.1.3/24 dev eth0
echo "192.168.1.4 webhost" | sudo tee -a /etc/hosts

#Checking if ufw installed

dpkg -s ufw &> /dev/null

if [ $? -ne 0 ]; then

    echo "UFW was not installed already."
    echo "Going to install UFW"
    apt-get install -y ufw > /dev/null


fi


EOF
