#!/bin/bash

#Assignment 2 - System Modification Assignment
#Name: Nicolas Blouin
#Student ID: 200410446
#Course Code: COMP2137
#Due Date: Wednesday, July 12th, 2023.

#Script Description:
#The purpose of my script is to alter the system configuration. This includes the system hostname,
#network settings, software installation, firewall altering, and lastly user accounts.
#This script will change specific files within the system using sequences of commands and condition tests.

#I am using an if statement to check whether or not the person trying to run the script
#is running with root privileges. By using the environment variable $EUID I am able to check effective user ID of the current user.
#When the current user ID when running the script is not equal to 0 meaning root I display an error message and
#exit 1 will terminate my script. the user ID needs to be a 0 to pass this check and
#run the remainder of my script. Using >&2 I am redirecting my echo message the output of errors.

if [ "$EUID" -ne 0 ]; then

  echo "This script must be run as sudo/root. Either be root user or use sudo with the command to ensure it runs correctly." >&2

  exit 1

fi

#This if statement takes the hostname variable of the system and compares
#it to the string autosrv using the != I specify if it is not equal to then run the code in this block
#I then echo the name autosrv into the hostname file on the system to persist it through rebooting
#then I set the host name using hostnamectl

if [[ $(hostname) != "autosrv" ]]; then

    echo "Updating the hostname"
    echo "autosrv" > /etc/hostname
    hostnamectl set-hostname autosrv

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

#using dpkg -s I can check the status of the package I want in this case openssh-server
#I then redirect unnecessary output to /dev/null.

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

    echo "Configuring SSH settings."

    echo "Setting password authentication to NO"

    #using sed -i I am editing the file directly with no backups. Essentially I am overwriting what is there.
    #using the s/ I am using subtitution to replace the text of PasswordAuthentication yes to a no.

    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

    #If the previous sed command had an exit status of 0 meaning success then I output a message saying settings applied

    if [ $? -eq 0 ]; then

        echo "Password authentication settings applied."

    #Using an else I am handling an error if the previous if statement did not trigger this else if ran.
    #I just mention the settings failed to apply and then exit 1 to terminate the script from running.

    else

        echo "Password authentication setting could NOT be applied. Stopping Script."
        exit 1

    fi

    echo "Setting SSH key authentication to YES"

    #using sed -i I am overwriting what is there using inplace editing.
    #using the s/ I am using subtitution to replace the text of PubkeyAuthentication no to a yes.

    sed -i 's/PubkeyAuthentication no/PubkeyAuthentication yes/' /etc/ssh/sshd_config

    #if the previous command was successful then the if statement will run due to exit status 0

    if [ $? -eq 0 ]; then

        echo "SSH Key authentication settings set successfully."

    #If the previous if statement did not run then this else is ran. Displaying an error message.
    #I terminate the script using exit 1

    else

        echo "SSH Key authentication settings could NOT be applied. Stopping script"
        exit 1

    fi

    echo "Restarting SSH..."

    #I then restart SSH services using systemctl restart command

    systemctl restart sshd

    #If the restart was a success then run this if block saying setup was complete

    if [ $? -eq 0 ]; then

        echo "SSH Setup complete."

    #if the previous if statement did not trigger then this else is ran.
    #I display an error message and terminate the script with exit 1.

    else

        echo "Failed to restart SSH and complete the setup. Exiting Script."
        exit 1

    fi

#If the previous if statement checking for if SSH was installed does not execute then run this else
#It displays some text saying SSH is already installed

else

    echo "SSH server is already installed."
    echo "Going to apply this scripts config settings for SSH"

    echo "Setting password authentication to NO"

    #Even if the system had SSH on it I wanted to ensure that the setting were correct so I ran the same code from above.
    #Using sed -i I am inplace overwriting the text within the file /etc/ssh/sshd_config
    #the /s is for substitution replacing PasswordAuthentication yes to a no

    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

    #if the sed command was successful then the if block runs saying set correctly

    if [ $? -eq 0 ]; then

        echo "Password authentication set correctly."

    #I use an else to handle an error. If the previous if statement did not execute then the else is ran
    #I display an error message and then terminate the script using exit 1.

    else

        echo "Password authentication was NOT successful. Stopping the Script."
        exit 1

    fi

    echo "Setting SSH key authentication to YES"

    #using sed I am replacing the text within my specified file /etc/ssh/sshd_config
    #using the /s I am substituting the text to set the pubkeyAuthentication text from no to yes

    sed -i 's/PubkeyAuthentication no/PubkeyAuthentication yes/' /etc/ssh/sshd_config

    #When the previous sed command works then I use an exit status check if statement to display some text saying it was set up

    if [ $? -eq 0 ]; then

        echo "SSH key authentication set correctly."

    #If the previous if statment did not execute then this else is ran. I did this to handle the errors.
    #I display an error message and then terminate the script using exit 1.

    else

        echo "SSH Key authentication was NOT setup correctly. Exiting Script."
        exit 1

    fi

    echo "Restarting SSH..."

    #I then restart the SSH service to apply the changes correctly

    systemctl restart sshd

    #if the exit status was a 0 it succeded and I show some text to output saying setup complete

    if [ $? -eq 0 ]; then

        echo "SSH setup Complete."

    #using the else statement I handle the error of when the exit status of the restart command above failed meaning not a 0.
    #I display an error and terminate the script using exit 1.

    else

        echo "SSH Restart and setup failed. Stopping Script."
        exit 1

    fi
fi

#I use a dpkg -s to check the status of the apache2 package this will check if it is installed on the system
#I then redirect to the null file to discard the output

dpkg -s apache2 &> /dev/null

#if the exit status of the dpkg command is not equal to 0 this means unsuccessful and it is not installed on the system
#The if statement will then be executed to install it.

if [ $? -ne 0 ]; then

    echo "Installing Apache2 web server..."

    #installing apache2 using apt-get and -y to say yes to all install prompts so the script isn't interupted

    apt-get install -y apache2 > /dev/null

    #if the install worked then the produced exit status of 0 will execute this if block saying installed.

    if [ $? -eq 0 ]; then

        echo "Installed Apache2."

    #When the previous if statement does not execute this else is ran to handle any errors. I display an error message.
    #I also terminate the script using exit 1

    else

        echo "Apache 2 was NOT installed correctly. terminating script"
        exit 1

    fi

    echo "Setting config for Apache2..."

    #I then enable the ssl module for apache using the a2enmod command

    a2enmod ssl > /dev/null

    #if the previous command executes correctly then the if statement will run as the exit status will check out as a 0

    if [ $? -eq 0 ]; then

        echo "Apache2 config enabled successfully."

    #By using an else I handle errors when the exit status is not 0. Since my previous if did not run there must have been an error.
    #I then display and error message and terminate the script by using exit 1.

    else

        echo "Apache2 config failed to enable. Stopping Script."
        exit 1

    fi

    echo "Restarting Apache2 to complete setup..."

    #restart the apache2 service using the system ctls restart command

    systemctl restart apache2

    #if the restart worked run this if statement as exit staus will be equal to 0

    if [ $? -eq 0 ]; then

        echo "Apache setup complete."

    #Using an else I am able to handle errors whenever my previous if statement did not execute as that would have checked succession.
    #I then display an error and terminate the script using exit 1.

    else

        echo "Apache Restart and setup has failed. Exiting Script."
        exit 1

    fi

#If the previous dpkg if statement did not execute then run this else

else

    echo "Apache2 web server is already installed."
    echo "Will apply settings to apache from this script..."

    #I am enabling the ssl module for apache2 using the a2enmod command

    a2enmod ssl > /dev/null

    #if this enabled command worked then run this if statement saying success as the exit status was a 0

    if [ $? -eq 0 ]; then

        echo "Apache settings applied successfully."

    #Using an else I handle potential errors whenever my previous if statement did not execute as that would have checked succession.
    #I then display an error and terminate the script using exit 1.

    else

        echo "Apache settings could NOT apply successfully. Terminating the Script."
        exit 1

    fi

    echo "Restarting Apache2 to complete setup..."

    #restart the apache2 service using systemctl restart command

    systemctl restart apache2

    #when the restart command is successful run this if statement as the exit status is equal to 0

    if [ $? -eq 0 ]; then

        echo "Apache setup complete."

    #when my if statement does not execute that will mean the exit status of the previous command failed. I can then use an else
    #to handle this error. I then display an error and terminate the script using exit 1.

    else

        echo "Apache Restart and setup failed. Stopping Script"
        exit 1

    fi

fi

#using dpkg -s to check the staus of squid to see if it is installed or not. when the exit status is anything but a 0
#the if statment below will trigger which will install squid as it is not on the system.

dpkg -s squid &> /dev/null

#if the previous dpkg command is not equal to a 0 run this if statement since squid is not installed

if [ $? -ne 0 ]; then

    echo "Installing Squid..."

    #run apt-get to install squid using a -y to accept all install prompts

    apt-get install -y squid > /dev/null

    #if the previous exit staus is a 0 squid install was a success and then run the if statment displaying installed

    if [ $? -eq 0 ]; then

        echo "Squid installed."

    #Using an else I can stop the script if the previous command failed meaning the exit status was not equal to 0.
    #so it will run the else instead. Using exit 1 it will terminate the script.

    else

        echo "Squid failed to install. Exiting the script"
        exit 1

    fi

    echo "Setting script config to squid settings..."

    #Using sed -i I am overwriting the text. using/s I am substituting http_port 3128 with http_port 3128
    #this is to ensure that this is the set port even though it seems redundant

    sed -i 's/http_port 3128/http_port 3128/' /etc/squid/squid.conf

    #if the replcament sed command worked then it will display settings applied as the if statment goes off due to exit status
    #evaluating to a 0

    if [ $? -eq 0 ]; then

        echo "Squid settings applied."

    #Using an else I will be able to exit the script when my if statement did not execute which would have check succession.
    #I display an error and then use exit 1 to terminate the script.

    else

        echo "Squid settings could NOT apply properly. Stopping Script."
        exit 1

    fi

    echo "Restarting Squid..."

    #restart squid service using systemctl restart command to ensure everything works and applies.

    systemctl restart squid

    #when the restart command works run this if statement since the exit status will be equal to 0 and say setup complete

    if [ $? -eq 0 ]; then

        echo "Squid setup complete."

    #Including an else to handle errors. When my previous if statement does not execute this else will go off
    #and display an error message as well as terminate my script using exit 1

    else

        echo "Squid Restart and setup failure. Quitting Script"
        exit 1

    fi

#if squid was installed already the above if statement checking would not have ran so the else goes off
#I then run the config commands again to ensure the system is setup correctly anyway

else

    echo "Squid web proxy is already installed."
    echo "Setting configuration of this script to squid..."

    #Using sed -i I am overwriting the text. using/s I am substituting http_port 3128 with http_port 3128.
    #This is redundant for ensuring the correct text is in place otherwise it doesn't exist and my if statment will tell me

    sed -i 's/http_port 3128/http_port 3128/' /etc/squid/squid.conf

    #if the exit staus is 0 then the sed command will have worked and the if statment will run saying setup correct

    if [ $? -eq 0 ]; then

        echo "Squid was setup correctly."

    #I use an else here to handle any potential errors when my previous if statement does not execute. I display an error message
    #and then exit the script using exit 1

    else

        echo "Squid was NOT configured properly. Terminating Script"
        exit 1

    fi

    echo "Squid is restarting..."

    #I then restart the squid service using the systemctl restart command

    systemctl restart squid

    #if the exit status is equal to 0 from the previous command then this if statement executes

    if [ $? -eq 0 ]; then

        echo "Squid setup complete."

    #Using an else I can manage any errors if my previous if statement did not execute this would pose an error that occured.
    #I then display an error message and terminate the script using exit 1

    else

        echo "Squid restart and setup failed. Terminating script"
        exit 1

    fi

fi

#Using dpkg -s I can check the install status of apg which is the automated password generator program. I redirect this
#command output to /dev/null so no unnecessary output is displayed.

dpkg -s apg &> /dev/null

#Using an if statement I am checking if the exit status of the last command is not equal to 0. If the previous command dpkg -s apg
#which was checking the install status evaulated to anything but a 0 this would mean the package is not installed and would run
#this if statement.

if [ $? -ne 0 ]; then

    echo "Automated Password Generator - apg is not installed on the system."
    echo "agp is needed for certain commands in this script."
    echo "Installing Automated Password Generator..."

    #Here I am installing the automated password generator - apg package with the -y option to automatically say yes to all prompts.
    #I redirect the output of the command to /dev/null to make sure unnecessary information is not included in the output.

    apt-get install -y apg > /dev/null

    #If the previous command installing apg had an exit status of 0 then that would mean success and this if will run
    #displaying that apg was installed.

    if [ $? -eq 0 ]; then

        echo "Automated Password Generator was installed successfully."

    #I have included an else to make sure if my previous if statement checking command succession does not execute then this
    #else will handle the error as the exit status of the apg install was not equal to 0 so it runs my else. I display an error
    #message and then terminate the script using exit 1

    else

        echo "Failed to install Automated Password Generator. Going to exit script"
        exit 1

    fi

#If the above if statement didn't run then the else statement is then triggered. This would mean the package is already installed.

else

    echo "Automated Password Generator is already installed."

fi

#this if statement is running the ufw status command. Once it runs it is piping the output to the grep command
#to search for the pattern of Status: active. By using -w the grep command will do a whole word search.
#if the phrase Status: active appears in the ufw status output then the if block runs.

if [[ $(ufw status | grep -w "Status: active") ]]; then

     echo "UFW firewall status already active."
     echo "Adding some tcp firewall rules on ports 22, 80, 443, and 3128."

     #Will add rules anyways even if the firewall is active
     #Setting all the ports I want to allow in the firewall configuration.

     ufw allow 22/tcp

     ufw allow 80/tcp

     ufw allow 443/tcp

     ufw allow 3128/tcp

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

    echo "Adding a few tcp firewall rules on ports 22, 80, 443, and 3128."

    ufw allow 22/tcp

    ufw allow 80/tcp

    ufw allow 443/tcp

    ufw allow 3128/tcp

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


#Creating my list of users to add onto the system per assignment requirements

users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

#Start of my for loop. This will loop through my users list that I had previously created.
#By stating ${users[@]} the @ will expand my list/array treating every
#item as its own word separately, I used this method to negate potential errors

for user in "${users[@]}"; do

    # Check if user already exists by checking the id of the user to see if it exists

    if id -u "$user" &> /dev/null; then

        echo "User '$user' already exists. Checking Next User."

    #if the user does not exist my else will run

    else

        #I use the useradd command to add the user with the variable name $user for whichever user is being itterated at the time
        #I use the -m option to make a home directory if it doesn't exist. I then use the -s to set the shell for the user
        #I specify the shell as /bin/bash

        sudo useradd -m -s /bin/bash "$user"

        echo "adding user $user..."

        # Generate random password using the built in automated password generator built into the linux operating system
        #-n for number of passwords to make and -m for min length.

        password=$(apg -n 1 -m 10)

        # Set the generated password for the user by passing in the user and generated password into the chpasswd command using a pipe

        echo "$user:$password" | sudo chpasswd

        #if the directory for the user in the list doesn't exist. then I create it.
        #by using -u I run the mkdir command and chmod command with the user's privileges
        #I then set permissions so the user can access the directory without issues

        if [ ! -d "/home/$user/.ssh" ]; then

            sudo -u "$user" mkdir "/home/$user/.ssh"
            sudo -u "$user" chmod 700 "/home/$user/.ssh"

        fi

        #I run an if statement using ! -f to check if the file does not exist. This file being /home/user/.ssh/id_rsa

        if [ ! -f "/home/$user/.ssh/id_rsa" ]; then

            #Then using -u I am running the command with the users privileges. I then generate an ssh key using ssh-keygen
            #using -t to specify the type of key to rsa. then -b for the bits of the key. I then use -f to specify where
            #to create the key. -q makes the creation of the key silent and -N quotes makes the creation of the
            #key to not require a password so my script will just run with no interuptions.

            sudo -u "$user" ssh-keygen -t rsa -b 4096 -f "/home/$user/.ssh/id_rsa" -q -N ""

        fi

        #This if statement uses ! -f to check if the file does not exist. The file I am checking for is /home/user/.ssh/id_ed25519
        #if it doesn't exist run the if statment.

        if [ ! -f "/home/$user/.ssh/id_ed25519" ]; then

            #Using -u the user privileges will be used for the following command. An ssh key is then generated using ssh-keygen
            #I specify the type using -t to be ed25519 and -f will specify where to put the created key this
            #being /home/user/.ssh/id_ed25519. Then using -q to make the key creation silent/quiet to the output. I then 
            #use -N quotes to make the passphrase requirement empty for key creation.

            sudo -u "$user" ssh-keygen -t ed25519 -f "/home/$user/.ssh/id_ed25519" -q -N ""

        fi

        #for the following cat commands I am appending the contents of the users key files id_rsa.pub and id_ed25519.pub
        #to the users authorized_keys file.

        cat "/home/$user/.ssh/id_rsa.pub" >> "/home/$user/.ssh/authorized_keys"
        cat "/home/$user/.ssh/id_ed25519.pub" >> "/home/$user/.ssh/authorized_keys"

        #Using chown I am setting the ownerwship of files and directories and giving it to the user. By using -R this is for recursive.
        #Meaning all of the directories, subdirectiories, and files will have the ownership changed to the user.
        #Using chmod 600 I am setting the user to have read and write permissions to authorized_keys

        sudo chown -R "$user:$user" "/home/$user/.ssh"
        sudo chmod 600 "/home/$user/.ssh/authorized_keys"

        echo "User '$user' created successfully."
        echo "Password for '$user' is: $password"

    fi
done

#Another for loop doing the same tasks as the previous for loop.
#This loop works by itterating through the list of specified users above. By using the @ it will expand the array treating every
#item as its own word separately, I used this method to negate potential errors

for user in "${users[@]}"; do

    #this if statement is checking if the user being iterrated is equal to the string dennis
    #As well as checkng if there is an id assosiated to dennis on the system. if dennis exists then the if statement executes.

    if [ "$user" = "dennis" ] && id -u "$user" &> /dev/null; then

        #by using the usermod command with option -aG command I am adding dennis to the sudo group

        sudo usermod -aG sudo dennis

        #using ! -d the if statement is checking if the directory /home/user/.ssh does not exist. If it doesn't exist then run the block of code 

        if [ ! -d "/home/$user/.ssh" ]; then

            #creates a directory called /home/user/.ssh using the users privileges
            #then chmod 700 will give read, write, and execute to the user for .ssh

            sudo -u "$user" mkdir "/home/$user/.ssh"
            sudo -u "$user" chmod 700 "/home/$user/.ssh"

        fi

        #Using ! -f the if statement is checking if the file /home/user/.ssh/id_rsa does not exist. Then run the block of code

        if [ ! -f "/home/$user/.ssh/id_rsa" ]; then

            #I am running the command with the users privileges by using option -u. I generate an ssh key using ssh-keygen
            # with the following option -t which will specify the type of key to rsa. specify the key bit length using -b.Then 
            #I then use -f for file to specify where to create the key. -q makes the creation of the key silent 
            #and -N quotes makes the creation of the key passwordless.

            sudo -u "$user" ssh-keygen -t rsa -b 4096 -f "/home/$user/.ssh/id_rsa" -q -N ""

            #if the ssh keygen command worked due to ahving a exit status of 0 meaning success
            #then display text the key was made for dennis

            if [ $? -eq 0 ]; then

                echo "Made RSA key for Dennis"

            fi
        fi

        #using ! -f will check if the file does not exist. If file /home/user/.ssh/id_ed25519 does not exist run the block of code

        if [ ! -f "/home/$user/.ssh/id_ed25519" ]; then

            #Using -u the privileges of the user are used for the following command. The command ssh-keygen will create an ssh key
            #I specify the type using -t to create an ed25519 key and -f will specify where the created key goes this
            #being /home/user/.ssh/id_ed25519. To make my output silent I used option -q for quiet. I then
            #make the password requirement empty using a -N with empty quotes.

            sudo -u "$user" ssh-keygen -t ed25519 -f "/home/$user/.ssh/id_ed25519" -q -N ""

            #If the key creation was a success then the if statement will execute as the exit status will be equal to 0

            if [ $? -eq 0 ]; then

                echo "Made ed25519 key for Dennis"

            fi
        fi

        #For the following cat commands. I am appending the contents of the id_rsa.pub and id_ed25519.pub to the users
        #authorized_keys file, this being for dennis.

        cat "/home/$user/.ssh/id_rsa.pub" >> "/home/$user/.ssh/authorized_keys"
        cat "/home/$user/.ssh/id_ed25519.pub" >> "/home/$user/.ssh/authorized_keys"

        #Give a key to dennis and append it to the file authorized_keys using the file path /home/dennis/.ssh/authorized_keys

        echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLnKfP0GSqbWSGYW/nC7UFLpfmgZTLUVlE2q1+jOHvDlUz+y0iCGdz+1WzILJeckv9EPaW1bVRLRuk1YQD9K7dGpXdRDM6Vt2g/EaQK+d+9L3aUhQj+6B3JlRGq+Yh0g/k0KvFCahUMyGNu47Vc6rHuKwM30be3Vi8biW1w/Sy2gGYevwM1byN3RkMDTy9LaLVf6OH9x/NM//xLJL5s6GjIKivAa3KBq63/3ZQZll3BlYp8bfwIFsKrBlLYW62UyrNG/ZiyL66XW6KlANMFg5/CQ3IvH/U9pQhStYP3p7PEKK5T4FS2trgsfU6JZxasufuK41UrYCDZ1FdMf user@example.com" >> "/home/dennis/.ssh/authorized_keys"

        #if the key was appended successfully the exit status of 0 will execute the if statement stating dennis had the key added

        if [ $? -eq 0 ]; then

            echo "Added Key to Dennis' key folder!"

        fi

    fi
done

#creating a variable called interface_name and storing my commands output into it.
#I am using the ip route command to then filter the output into awk. I am filtering specifically for default
#and then going 5 fields from that reference point. This being the systems ethernet interface.
#I then use this in my net plan config.

interface_name=$(ip route | awk '/default/ {print $5}')

#I then set a variable storing my net plan config. Using the address and servers according to the assignment.

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
        search: [home.arpa, localdomain]
"

#I make a new variable called new_netplan which creates a new netplan file on the system

new_netplan="/etc/netplan/new_netplan_config.yaml"

#After creating a netplan config and a new netplan file, I then pipe my output of my echo config command into the tee command
#which will write the echo contents into my new_netplan file.

echo "$config" | sudo tee "$new_netplan" > /dev/null

#I am then applying my netplan settings to the system and discarding my outputs of the command to /dev/null

sudo netplan apply &> /dev/null

#if the netplan apply command works then the exit status will result to 0 which runs my if statement displaying netplan applied

if [ $? -eq 0 ]; then

    echo "Netplan configuration was applied!"

#When my if statement above checking if the netplan apply command had an exit status of 0 meaning successful does not evaluate then
#my else would then be executed displaying an error message and I terminate the script using exit 1

else

    echo "Netplan configuration failed"
    exit 1

fi
