#!/bin/bash

#Assignment 3 - Automated Configuration Assignment
#Name: Nicolas Blouin
#Student ID: 200410446
#Course Code: COMP2137
#Due Date: Wednesday, August 4th, 2023.

#user id check
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

    echo "UFW is not installed."
    echo "Going to install UFW"
    apt-get install -y ufw > /dev/null


    if [ $? -eq 0  ]; then

        echo "Successfull installed UFW"

    else

        echo "UFW Install failed! Terminating the script"
        exit 1

    fi

else

    echo "UFW is already installed."

fi

#this if statement is running the ufw status command. Once it runs it is piping the output to the grep command
#to search for the pattern of Status: active. By using -w the grep command will do a whole word search.
#if the phrase Status: active appears in the ufw status output then the if block runs.

if [[ $(ufw status | grep -w "Status: active") ]]; then

     echo "UFW firewall status already active."
     echo "Adding firewall rules."

     #Will add rules anyways even if the firewall is active
     #Setting all the ports I want to allow in the firewall configuration.

     ufw allow from 172.16.1.0/24 to any port 514/udp

     echo "Restarting/Reloading the firewall"

     #restarting the firewall to apply the new changes using the ufw reload command.

     ufw reload

     #Using an if I can evaluate if the exit status of the ufw reload command was a 0 meaning a success.
     #I then display a success message

     if [ $? -eq 0 ]; then

         echo "Firewall was successfully Restarted/Reloaded."

     #When the above if statement is not ran then that would mean an exit status other than 0 occured.
     #My else statement will then execute displaying an error and I terminate the script with an exit 1.

     else

         echo "Firewall could NOT restart. Terminating script."
         exit 1

     fi

#when the firewall is not on run the else and enable it and apply rules to allow my listed ports

else

    echo "Turning on UFW firewall."

    #turn on the firewall using ufw enable command

    ufw enable

    #If the exit status of my previous ufw enable command was 0 meaning success then run this if statement.
    #I display a success message.

    if [ $? -eq 0 ]; then

        echo "Firewall was turned on successfully."

    #When the previous if statement does not execute that would mean that the last command failed. This command being ufw enable
    #I then use an else to handle the error displaying a message and terminating the script using exit 1.

    else

        echo "Firewall failed to enable and turn on. Stopping the script"
        exit 1

    fi

    echo "Adding a few tcp firewall rules."

    ufw allow from 172.16.1.0/24 to any port 514/udp

    echo "Restarting firewall"

    #restart the firewall to apply my settings using the ufw reload command

    ufw reload

    #Using an if to check if the exit status of my ufw reload command was a 0 meaning success. If a 0 then run this if statement.

    if [ $? -eq 0 ]; then

        echo "Firewall restarted successfully."

    #When the above if statement is not executed then the exit status of ufw reload was something other than a 0.
    #My else statement will then execute displaying an error and I terminate the script with an exit 1.

    else

        echo "Firewall could NOT restart properly. Terminating script"
        exit 1

    fi


    echo "Firewall turned on and setup was successful!"

fi

#Rsyslog stuff

sed -i 's/#module(load="imudp")/module(load="imudp")/' /etc/rsyslog.conf
sed -i 's/#input(type="imudp" port="514")/input(type="imudp" port="514")/' /etc/rsyslog.conf

EOF
