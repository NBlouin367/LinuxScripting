#!/bin/bash

#Assignment 3 - Automated Configuration Assignment
#Name: Nicolas Blouin
#Student ID: 200410446
#Course Code: COMP2137
#Due Date: Friday, August 4th, 2023.


#Script Description:
#The purpose of my script is to alter the remoteloy connect to target machines and change
#the configurations on the remote machine

#I am using an if statement to check whether or not the person trying to run the script
#is running with root privileges. By using the environment variable $EUID I am able to check effective user ID of the current user.
#When the current user ID when running the script is not equal to 0 meaning root I display an error message and
#exit 1 will terminate my script. the user ID needs to be a 0 to pass this check and
#run the remainder of my script.

if [ "$EUID" -ne 0 ]; then

    echo "This script must be run as sudo/root. Either be root user or use sudo with the command to ensure it runs correctly." >&2

    exit 1

fi

echo "Updating package list, so packages install correctly on host machine"

#Update the packages on the machine running the script so that open ssh will install with the most
#updated packages

apt-get update > /dev/dell

echo "Checking if SSH is installed before proceeding"

#I check the status of openssh-server using dpkg -s to check if the package is on the system or not

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

#Storing the value remoteadmin@172.16.1.10 into a variable called target1_management to use later for ssh connections

target1_management="remoteadmin@172.16.1.10"


#I am now using ssh to connect to the target 1 machine using the remote address
#using StrictHostKeyCheck this will disable the prompt for the user to type y when connecting
#this will ensure the script doesn't need to pause.

if ssh -o StrictHostKeyChecking=no "$target1_management" << EOF


   echo "Going to configure target1"
   echo "Making sure packages are updated on this machine"

   #I am updating the target1 machine packages to make sure it has the most recent for
   #needed installs of packages in my script

   apt-get update > /dev/null

   #Using an if I can check if the host name is not equal to log host. if it isn't set to log host
   #this if block is ran

   if [[ $(hostname) != "loghost" ]]; then

       echo "Updating the hostname to loghost"

       #I am adding loghost to the hostname file and then using hostnamectl set-hostname
       #I can set the machine name to loghost

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

   #Adding IP address on the target 1 machine using ip addr add command

   echo "Setting IP address to host 3 on the LAN"

   ip addr add 192.168.16.3/24 dev eth0

   #if the previous ip add command works then the exit status of 0 will make this if statement run
   #saying the IP was setup

   if [ $? -eq 0 ]; then

       echo "Successfully set IP to host number 3"

   #otherwise if the exit staus was not a 0 it failed so this else if ran saying IP was not setup

   else

       echo "IP could not be setup correctly. Terminating script"
       exit 1

   fi

   #Adding machine webhost to /etc/hosts
   #using the echo command I am adding the address of 198.168.16.4 and the name webhost next to it
   #into /etc/hosts. By using a pipe I am taking the echo value and passing into the tee command which
   #writes it my specified location being /etc/hosts

   echo "Adding machine webhost to /etc/hosts"

   echo "198.168.16.4 webhost" | sudo tee -a /etc/hosts

   #when the previous command was successful an if block will execute saying success as the exit
   #status was 0

   if [ $? -eq 0 ]; then

       echo "Successfully added machine webhost"

   #else is ran if the previous if didn't execute and exits the script using exit 1 indicating failure

   else

       echo "Failed to add webhost. Exiting Script."
       exit 1

   fi

   #Checking if ufw is installed using dpkg -s to see if it's on the system

   dpkg -s ufw &> /dev/null

   #when the exit status of the package check status is not equal to 0 meaning uninstalled, the if
   #will run

   if [ $? -ne 0 ]; then

       echo "UFW is not installed."
       echo "Going to install UFW"

       #I then use apt-get to install ufw on the system using -y it will say yes to all prompts
       #automatically so the script runs without stopping

       sudo apt-get install -y ufw > /dev/null

       #when the previous command of ufw installing is exit status 0 the if is ran saying success

       if [ $? -eq 0 ]; then

           echo "Successfull installed UFW"


       #This else if ran if the previous if didn't execute maing the ufw failed to install
       #Then using exit 1 I stop the script

       else

           echo "UFW Install failed! Terminating the script"
           exit 1

       fi

   #when the connected if statement above doesn't execute then ufw was already installed
   #and this else is ran syaing it's already installed

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

   #Using sed -i option, this will make sure the file it edited directly. The file being modified here is the rsyslog.conf file
   #the purpose of this command is to use substitution to replace the lines commented #module line I specified
   #with the uncommented text I specified.

   sed -i 's/#module(load="imudp")/module(load="imudp")/' /etc/rsyslog.conf

   #if the exit status of my previous sed command was 0 meaning it was successful and made the edits then I say success

   if [ $? -eq 0 ]; then

       echo "Successfully uncommented lines."

   fi

   #using sed with the option -i meaning in place, i am editing the rsyslog.conf directly.
   #My sed command is using substitution to replace the commented lines I specified with uncommented lines I specified.

   sed -i 's/#input(type="imudp" port="514")/input(type="imudp" port="514")/' /etc/rsyslog.conf

   #if the previous sed command was succcessful the this if statement will execute due to exit status being equal to 0
   #I then print a success message

   if [ $? -eq 0 ]; then

       echo "Successfully uncommented lines to enable UDP listening on port 514"

   fi

   echo "Restarting rsyslog..."

   #I am now restarting rsyslog using systemctl restart command

   systemctl restart rsyslog

   #if the previous systemctl command was a success this if statement runs due to
   #exit staus being equal to 0

   if [ $? -eq 0 ]; then

       echo "Succesfully restarted rsyslog"

   #when the exit staus was not equal to 0 then the else is ran, i output an error message and
   #terminate the script with exit

   else

       echo "Could not restart rsyslog. Exiting script"
       exit 1

   fi

   #using the systemctl is-active command I can check if rsyslog is running using -q I just keep the output quiet

   if systemctl is-active -q rsyslog; then

      echo "Rsyslog is running on loghost"

   #If it isn't running then the else is ran and the script will terminate. The reason I exit it instead of
   #trying to start it up was in the code above i have already restarted ryslog so it should be running.

   else

       echo "Rsyslog is not running on log host. Terminating Script"
       exit 1

   fi

#end of the SSH target1 session commands block

EOF

#If all the previous commands in the SSH session were successful I print a message out saying success.

then

    echo "The previous configurations were successfull. No exit codes were set off"

#if anything was unsuccessful then the script will terminate. The checks within the SSH should have caught errors
#but this is just backup text

else

    echo "Failed to apply configurations. Stopping script"
    exit 1

fi

#Start of target 2 commands
#I make a variable called target2_management and store remoteadmin@172.16.1.11 into it.

target2_management="remoteadmin@172.16.1.11"

#I now initiate an SSH session on target2 using the ssh command with the target@_management variable I made above
#I use StrictHostKeyChecking set to no so that the user will not have to interact with the keyboard
#and the script will just run automatically without interruptions

if ssh -o StrictHostKeyChecking=no "$target2_management" << EOF

   echo "Configuring target 2 settings"
   echo "Making sure packages are updated on this machine"

   #I update the machines packages to the most recent

   apt-get update > /dev/null

   #I am then checking if apache2 is installed, using dpkg -s to check the status. If the package is not
   #installed then this block is ran below.

   if ! dpkg -s apache2 &> /dev/null; then

       echo "Apache2 is not installed."
       echo "Going to install Apache2."

       #This will install apache2 on the system using -y will ensure all prompts are answered yes
       #so that my script is not stopped and runs without user interaction

       sudo apt-get install -y apache2 &> /dev/null

       #when the exit status of the previous apache2 install is 0 then the if statement is ran saying success

       if [ $? -eq 0 ]; then

           echo "Successfull installed Apache2"
           echo "Starting apache2"

           #I then ensure apache2 is started using the systemctl start Apache2 command

           sudo systemctl start apache2

           #I check if Apache2 is running using systemctl is-active. using -q I keep the output quiet.
           #if it is running then say it's active

           if systemctl is-active -q apache2; then

               echo "Started Apache2 success and is active"

           #the else is executed when the above if is not triggered. This would indicate that Apache2 is no
           #running then this means it failed to start from the above command. So I exit the script as it failed to start.

           else

               echo "Failed to start Apache2"
               exit 1

           fi

       echo "Going to enable Apache2 for startups for future system boots"

       #I then enable Apache2 to make sure it will startup again if the machine were to be restarted

       systemctl enable apache2

       #when the previous if statement above for this block didn't execute this means exit status of apache2 was
       #not a 0 meaning failure so the else is ran, so I exit the script with an error message

       else

           echo "Apache Install failed! Terminating the script"
           exit 1

       fi

   #if the above if statement for this block didn't trigger this would mean Apache2 was already installed.
   #so the else is ran and I give a message saying Apache2 is installed

   else

       echo "Apache2 is already installed."

   fi

   #If the hostname on this machine is not equal to webhost then this if statment is ran to change it

   if [[ $(hostname) != "webhost" ]]; then

       echo "Updating the hostname to webhost"

       #I add webhost to /etc/hostname, I then set the hostname on the machine to webhost using
       #the hostnamectl set-hostname command

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


   echo "Setting IP address to host 4 on the LAN"

   #Using the ip addr add command I am adding the following IP to the target2 machine

   ip addr add 192.168.16.4/24 dev eth0

   #if the exit status of the previous ip addr add command
   #was a 0 meaning success then say successful

   if [ $? -eq 0 ]; then

       echo "Successfully set IP to host number 4"

   #since the  above if statement didn't execute that means the exit status was not a 0.
   #This would mean the IP command failed. I say it was not setup and exit the script

   else

       echo "IP could not be setup correctly. Terminating script"
       exit 1

   fi


   echo "Adding machine loghost to /etc/hosts"

   #I add the address 192.168.16.3 and the name loghost to the /etc/hosts file using a pipe into
   #the tee command which will write contents to my specified file. Using -a I append the contents.

   echo "192.168.16.3 loghost" | sudo tee -a /etc/hosts

   #if the previous command gave an exit status of 0 meaning success, the if statement is ran
   #and I print out a message sating successfully added

   if [ $? -eq 0 ]; then

       echo "Successfully added machine loghost"

   #since the previous if didn't trigger then the exit status would have been anything but a 0
   #so my else is ran and I say failed and exit the script

   else

       echo "Failed to add loghost. Exiting Script."
       exit 1

   fi



   #I check if ufw is installed on the machine using dpkf -s to retrieve
   #the status of the package

   dpkg -s ufw &> /dev/null

   #when the exit status of the previous dpkg command is not equal to 0 this will mean it isn't
   #installed so my if statement will then run

   if [ $? -ne 0 ]; then

       echo "UFW is not installed."
       echo "Going to install UFW"

       #I then installed ufw on the system and use -y to say yes
       #to all the install prompts

       sudo apt-get install -y ufw > /dev/null

       #When the previous command installing ufw gives an exit status 0, this means that
       #it was a success and this if statement is ran saying success

       if [ $? -eq 0 ]; then

           echo "Successfull installed UFW"

       #when the above if is not ran then this else would run. This  would mean the ufw install gave
       #an exit status of anything but a 0 which is a failure. I say failure message and end the script

       else

           echo "UFW Install failed! Terminating the script"
           exit 1

       fi

   #when the above if statement that checks for ufw installation is not ran this
   #means ufw was already installed. I then say ufw is already installed

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

   #I am using echo *.* @loghost and piping it to the tee command which
   #will write my echo contents to the file I specify, this file being rsyslog.conf.
   #I use the -a option to append to the file so it won't just overwrite.

   echo "*.* @loghost" | sudo tee -a /etc/rsyslog.conf

   #If the previous command gave an exit status of 0, that would mean success
   #so then my if statement is ran saying success

   if [ $? -eq 0 ]; then

       echo "*.* @loghost added to /etc/rsyslog.conf success"

   #when the above if statement doesn't execute then my else is ran.
   #this would mean the exit code wasn't 0, meaning an error.
   #I then say failed in the output and stop the script

   else

       echo "Failed to add *.* @loghost to /etc/rsyslog.conf. Stopping Script"
       exit 1

   fi

#This is the end of my target2 SSH session commands block

EOF

#if no errors occured then I say success for target2 settings. Previous errors should be caught
#by my error checking.

then

    echo "Target2 settings were updated successfully. No error exit status codes from previous commands."

#If something errors within the SSH session then an extra error message is outputted
#the script is also terminated

else

    echo "Target2 settings failed to configure correctly. Exiting Script"
    exit 1

fi



echo "Configuring NMS Settings..."

#using sed I am using the -i option to set inplace editing so the file is being edited.
#This will search for lines within /etc/hosts that contain loghost or webhost and delete them
#hence the d at the end of the sed command. I am emptying the hosts file so I can't produce duplicates
#if the system were to have loghost and webhost already

sed -i '/\(loghost\|webhost\)/d' /etc/hosts

#I am using echo command then piping the output to the tee command to write
#the contents 192.168.16.3 loghost into /etc/hosts. Using the tee command with the -a option
#makes it append the contents to the file I specfied, this being /etc/hosts.

echo "192.168.16.3 loghost" | sudo tee -a /etc/hosts

#When my previous command exit status is a 0, this if statement runs saying success

if [ $? -eq 0 ]; then

    echo "Successfully added loghost to /etc/hosts"

#When the above if statement doesn't run this else is then ran.
#This would mean the exit status of the previous command was anything but a 0
#which is an error. I then say error and terminate the script

else

    echo "Failed to add loghost to /etc/hosts. Stopping the script"
    exit 1

fi

#Adding 192.168.16.4 webhost to /etc/hosts. I use the echo command
#with my text, I then pipe into the tee command. What this does is
#writes it to the file I specified, this being /etc/hosts.
#When using the tee command with the -a option, I am appending to my specified file,
#this file being /etc/hosts

echo "192.168.16.4 webhost" | sudo tee -a /etc/hosts

#Using this if statment I am checking the exit status of the previous command
#If the exit status is 0 that means success, this if statment will run and
#It will then say success

if [ $? -eq 0 ]; then

    echo "Successfully added loghost to /etc/hosts"

#when the above if statement does not execute this else statement will run.
#This would mean the exit status of my previous command was gave anything but a 0
#meaning an error occured. I then say failed and exit the script

else

    echo "Failed to add loghost to /etc/hosts"
    exit 1

fi

#I am using dpkg -s to check the status of curl to see if it
#is installed on the system.

dpkg -s curl &> /dev/null

#when the exit status of the previous dpkg status command is not equal to 0 then run the package install
#since it is not installed on the system.

if [ $? -ne 0 ]; then

    echo "Installing curl to check webpage"

    #installing curl using the -y option just automatically assumes yes for all the install prompts

    apt-get install -y curl > /dev/null

    #when the exit status of the previous command is 0 meaning success run this if statment saying install complete

    if [ $? -eq 0 ]; then

        echo "curl install complete."

    #When the above if statement doesn't execute, then this else statement will run.
    #This would mean the previous command gave an exit status of anything but a 0
    #This means an error, I then say failed and exit the script

    else

        echo "Curl failed to install. Terminating Script"
        exit 1

    fi
fi

#Using an if statement, I am checking if I can retrieve the contents of http://webhost
#if curl can retrieve the contents I then take that output and pipe it into the grep command
#using grep I am searching for the text Apache2 Default Page, which is the home page headline
#if all these conditions are met then I will say success

if curl -s "http://webhost" | grep -q "Apache2 Default Page"; then

   echo "Successfully found webpage at http://webhost"

#when the above if statement doesn't execute then that would mean the conditions of finding the webpage were not met
#the else statement will then run saying failure. Exit was not needed here as this is the end of the script

else

    echo "Failed to find webhost page at hhtp://webhost"

fi
