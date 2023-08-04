#!/bin/bash

#Assignment 3 - Automated Configuration Assignment
#Name: Nicolas Blouin
#Student ID: 200410446
#Course Code: COMP2137
#Due Date: Wednesday, August 4th, 2023.

#updated script

#user id check

if [ "$EUID" -ne 0 ]; then

    echo "This script must be run as sudo/root. Either be root user or use sudo with the command to ensure it runs correctly." >&2

    exit 1

fi

echo "Updating package list, so packages install correctly on host machine"

apt-get update > /dev/dell

echo "Checking if SSH is installed before proceeding"

dpkg -s openssh-server &> /dev/null

#when the exit status of the previous dpkg status command is not equal to 0 then run the package installs
#since it is not installed on the system.

if [ $? -ne 0 ]; then

    echo "Installing SSH server..."

    #installing openssh-server using the -y option just automatically assumes yes for all the install prompts.

    apt-get install -y openssh-server > /dev/null

    #when the exit status of the previous command is 0 meaning success run this if statment saying ssh install complete.

    if [ $? -eq 0 ]; then

        echo "openssh install complete."

    #Using an else statement. This will handle an error. If the previous if statement checking exit status was not
    #0 meaning success this else is then run and I use exit 1 to terminate the script with an error message.

    else

        echo "openssh failed to install. Terminating Script"
        exit 1

    fi
fi

target1_management="remoteadmin@172.16.1.10"


if ssh -o StrictHostKeyChecking=no "$target1_management" << EOF


   echo "Going to configure target1"
   echo "Making sure packages are updated on this machine"

   apt-get update > /dev/null

   if [[ $(hostname) != "loghost" ]]; then

       echo "Updating the hostname to loghost"
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

   echo "Setting IP address to host 3 on the LAN"

   ip addr add 192.168.16.3/24 dev eth0

   if [ $? -eq 0 ]; then

       echo "Successfully set IP to host number 3"

   else

       echo "IP could not be setup correctly. Terminating script"
       exit 1

   fi

   #Adding machine webhost to /etc/hosts

   echo "Adding machine webhost to /etc/hosts"

   echo "198.168.16.4 webhost" | sudo tee -a /etc/hosts

   if [ $? -eq 0 ]; then

       echo "Successfully added machine webhost"

   else

       echo "Failed to add webhost. Exiting Script."
       exit 1

   fi

   #Checking if ufw is installed

   dpkg -s ufw &> /dev/null

   if [ $? -ne 0 ]; then

       echo "UFW is not installed."
       echo "Going to install UFW"

       sudo apt-get install -y ufw > /dev/null


       if [ $? -eq 0 ]; then

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


   if ufw status | grep -w -q "Status: active"; then

       echo "UFW firewall status already active."
       echo "Adding firewall rules."

       #Will add rules anyways even if the firewall is active
       #Setting all the ports I want to allow in the firewall configuration.

       ufw allow proto udp from 172.16.1.0/24 to any port 514
       ufw allow 22/tcp
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

       ufw --force enable

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

       echo "Adding firewall rules."

       ufw allow proto udp from 172.16.1.0/24 to any port 514
       ufw allow 22/tcp

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

   if [ $? -eq 0 ]; then

       echo "Successfully uncommented lines."

   fi

   sed -i 's/#input(type="imudp" port="514")/input(type="imudp" port="514")/' /etc/rsyslog.conf

   if [ $? -eq 0 ]; then

       echo "Successfully uncommented lines to enable UDP listening on port 514"

   fi


   #Restart rsyslog

   echo "Restarting rsyslog..."

   systemctl restart rsyslog

   if [ $? -eq 0 ]; then

       echo "Succesfully restarted rsyslog"

   else

       echo "Could not restart rsyslog. Exiting script"
       exit 1

   fi


   systemctl is-active rsyslog | grep -q "active"

   if [ $? -eq 0 ]; then

       echo "Rsyslog is running on loghost"

   else

       echo "Rsyslog is not running on log host. Terminating Script"
       exit 1

   fi

   grep -q "webhost" /var/log/syslog

   if [ $? -eq 0 ]; then

       echo "Logs are being received from webhost"

   else

       echo "Logs are not being received. Stopping Script"
       exit 1

   fi


   echo "logging out of SSH Session on target 1"


EOF

then

    echo "The previous configurations were successfull. No exit codes were set off"

else

    echo "Failed to apply configurations. Stopping script"
    exit 1

fi

#Start of target 2 commands

target2_management="remoteadmin@172.16.1.11"

if ssh -o StrictHostKeyChecking=no "$target2_management" << EOF

   echo "Configuring target 2 settings"
   echo "Making sure packages are updated on this machine"

   apt-get update > /dev/null

   if ! dpkg -s apache2 &> /dev/null; then

       echo "Apache2 is not installed."
       echo "Going to install Apache2."

       sudo apt-get install -y apache2 &> /dev/null


       if [ $? -eq 0 ]; then

           echo "Successfull installed Apache2"
           echo "Starting apache2"

           sudo systemctl start apache2

           if systemctl is-active -q apache2; then

               echo "Started Apache2 success and is active"

           else

               echo "Failed to start Apache2"
               exit 1

           fi

       echo "Going to enable Apache2 for startups for future system boots"
       systemctl enable apache2

       else

           echo "Apache Install failed! Terminating the script"
           exit 1

       fi

   else

       echo "Apache2 is already installed."

   fi

   if [[ $(hostname) != "webhost" ]]; then

       echo "Updating the hostname to webhost"
       echo "webhost" > /etc/hostname
       hostnamectl set-hostname webhost

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


   #Setting IP address on on management 2

   echo "Setting IP address to host 4 on the LAN"

   ip addr add 192.168.16.4/24 dev eth0

   if [ $? -eq 0 ]; then

       echo "Successfully set IP to host number 4"

   else

       echo "IP could not be setup correctly. Terminating script"
       exit 1

   fi

   #Adding machine losthost to /etc/hosts

   echo "Adding machine loghost to /etc/hosts"

   echo "192.168.16.3 loghost" | sudo tee -a /etc/hosts

   if [ $? -eq 0 ]; then

       echo "Successfully added machine loghost"

   else

       echo "Failed to add loghost. Exiting Script."
       exit 1

   fi



   #firewall portion

   dpkg -s ufw &> /dev/null

   if [ $? -ne 0 ]; then

       echo "UFW is not installed."
       echo "Going to install UFW"

       sudo apt-get install -y ufw > /dev/null


       if [ $? -eq 0 ]; then

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


   if  ufw status | grep -w -q "Status: active"; then

       echo "UFW firewall status already active."
       echo "Adding firewall rules."

       #Will add rules anyways even if the firewall is active
       #Setting all the ports I want to allow in the firewall configuration.

       ufw allow 80/tcp
       ufw allow 22/tcp

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

       ufw --force enable

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

       ufw allow 80/tcp
       ufw allow 22/tcp

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


   echo "*.* @loghost" | sudo tee -a /etc/rsyslog.conf

   if [ $? -eq 0 ]; then

       echo "*.* @loghost added to /etc/rsyslog.conf success"

   else

       echo "Failed to add *.* @loghost to /etc/rsyslog.conf"

   fi

EOF

then

    echo "Target2 settings were updated successfully. No error exit status codes from previous commands."

else

    echo "Target2 settings failed to configure correctly. Exiting Script"
    exit 1

fi


echo "Configuring NMS Settings..."


sed -i '/\(loghost\|webhost\)/d' /etc/hosts

echo "192.168.16.3 loghost" | sudo tee -a /etc/hosts

if [ $? -eq 0 ]; then

    echo "Successfully added loghost to /etc/hosts"

else

    echo "Failed to add loghost to /etc/hosts"

fi

echo "192.168.16.4 webhost" | sudo tee -a /etc/hosts

if [ $? -eq 0 ]; then

    echo "Successfully added loghost to /etc/hosts"

else

    echo "Failed to add loghost to /etc/hosts"

fi

dpkg -s curl &> /dev/null

#when the exit status of the previous dpkg status command is not equal to 0 then run the package instal>
#since it is not installed on the system.

if [ $? -ne 0 ]; then

    echo "Installing curl to check webpage"

    #installing curl using the -y option just automatically assumes yes for all the install p>

    apt-get install -y curl > /dev/null

    #when the exit status of the previous command is 0 meaning success run this if statment saying ssh >

    if [ $? -eq 0 ]; then

        echo "curl install complete."

    #Using an else statement. This will handle an error. If the previous if statement checking exit sta>
    #0 meaning success this else is then run and I use exit 1 to terminate the script with an error mes>

    else

        echo "curl failed to install. Terminating Script"
        exit 1

    fi
fi


if curl -s "http://webhost" | grep -q "Welcome to apache"; then

   echo "Successfully found webhost webpage at http://webhost"

fi
