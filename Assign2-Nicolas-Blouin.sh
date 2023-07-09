#!/bin/bash

#Assignment 2 - System Modification Assignment
#Name: Nicolas Blouin
#Student ID: 200410446
#Course Code: COMP2137

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
    fi

    #if the exit status not equal to 0 meaning unsuccessful then display it failed

    if [ $? -ne 0 ]; then
       echo "Hostname change failed!"
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

    #installing openssh-server using the -y option just automatically assumes yes for all the install prompts

    sudo apt-get install -y openssh-server > /dev/null

    if [ $? -eq 0 ]; then
        echo "openssh install complete."
    fi

    echo "Configuring SSH settings."

    echo "Setting password authentication to NO"

    #using sed -i I am editing the file directly with no backups. Essentially I am overwriting what is there.
    #using the s/ I am using subtitution to repplace the text of PasswordAuthentication yes to a no.

    sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

    #If the previous sed command had an exit status of 0 meaning success then I output a message saying settings applied

    if [ $? -eq 0 ]; then
        echo "Password authentication settings applied."
    fi

    echo "Setting SSH key authentication to YES"

    #using sed -i I am overwriting what is there using inplace editing.
    #using the s/ I am using subtitution to repplace the text of PubkeyAuthentication no to a yes.

    sudo sed -i 's/PubkeyAuthentication no/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    if [ $? -eq 0 ]; then
        echo "SSH Key authentication settings set successfully."
    fi


    echo "Restarting SSH."

    #I then restart SSH services using systemctl restart command

    sudo systemctl restart sshd

    #If the restart was a success then run this if block saying setup was complete

    if [ $? -eq 0 ]; then
        echo "SSH Setup complete.."
    fi

#If the previous if statement checking for if SSH was installed does not execute then run this else
#It displays some text saying SSH is already installed

else
    echo "SSH server is already installed."
    echo "Going to apply this scripts config settings for SSH" 

    echo "Setting password authentication to NO"

    #Even if the system had SSH on it I wanted to ensure that the setting were correct so I ran tthe same code from above.
    #Using sed -i I am inplace overwriting the text within the file /etc/ssh/sshd_config
    #the /s is for substitution replacing PasswordAuthentication yes to a no 

    sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

    #if the sed command was successful then the if block runs saying set correctly

    if [ $? -eq 0 ]; then
        echo "Password authentication set correctly."
    fi

    echo "Setting SSH key authentication to YES"

    #using sed I am replacing the text within my specified file /etc/ssh/sshd_config
    #using the /s I am substituting the text to set the pubkeyAuthentication text from no to yes

    sudo sed -i 's/PubkeyAuthentication no/PubkeyAuthentication yes/' /etc/ssh/sshd_config

    #When the previous sed command works then I use an exit status check if statement to display some text saying it was set up

    if [ $? -eq 0 ]; then
        echo "SSH key authentication set correctly."
    fi

    echo "Restarting SSH."

    #I then restart the SSH service to apply the changes correctly

    sudo systemctl restart sshd

    #if the exit status was a 0 it succeded and I show some text to output saying setup complete

    if [ $? -eq 0 ]; then
        echo "SSH setup Complete."
    fi
fi

#I use a dpkg -s to check the status of the apache2 package this will check if it is installed on the system
#I then redirect to the null file to discard the output

dpkg -s apache2 &> /dev/null

#if the exit status of the dpkg command is not equal to 0 this means unccessful and it is not installed on the system
#The if statement will then be executed to install it.

if [ $? -ne 0 ]; then
    echo "Installing Apache2 web server..."

    #installing apache2 using apt-get and -y to say yes to all install prompts so the script isn't interupted

    sudo apt-get install -y apache2 > /dev/null

    #if the install worked then exit status 0 will execute this if block saying installed.

    if [ $? -eq 0 ]; then
        echo "Installed Apache2."
    fi

    echo "Setting config for Apache2."

    #I then enable the ssl module for apache using the a2enmod command

    sudo a2enmod ssl > /dev/null

    #if the previous command executes correctly then the if statement will run as the exit status will check out as a 0

    if [ $? -eq 0 ]; then
        echo "config enabled successfully."
    fi

    echo "Restarting Apache2 to complete setup."

    #restart the apache2 service using the system ctls restart command

    sudo systemctl restart apache2
 
    #if the restart worked run this if statement as exit staus will be equal to 0

    if [ $? -eq 0 ]; then
        echo "Apache setup complete."
    fi

#If the previous dpkg  if statement did not execute then run this else

else
    echo "Apache2 web server is already installed."
    echo "Will apply settings to apache from this script."

    #I am enabling the ssl module for apache2 using the a2enmod command

    sudo a2enmod ssl > /dev/null

    #if this enabled command worked then run this if statement saying success

    if [ $? -eq 0 ]; then
        echo "Apache settings applied successfully."
    fi

    echo "Restarting Apache2 to complete setup."

    #restart the apache2 service using systemctl restart command

    sudo systemctl restart apache2

    #when the restart command is successful run this if statement as the exit status is equal to 0

    if [ $? -eq 0 ]; then
        echo "Apache setup complete."
    fi

fi



dpkg -s squid &> /dev/null
if [ $? -ne 0 ]; then

    echo "Installing Squid web proxy..."
    sudo apt-get install -y squid > /dev/null
    if [ $? -eq 0 ]; then
        echo "Squid installed."
    fi

    # Configure Squid
    echo "Setting script config to squid settings."
    sudo sed -i 's/http_port 3128/http_port 3128/' /etc/squid/squid.conf

    if [ $? -eq 0 ]; then
        echo "Squid settings applied."
    fi

    echo "restarting Squid."
    sudo systemctl restart squid
    if [ $? -eq 0 ]; then
        echo "Squid setup complete."
    fi
else
    echo "Squid web proxy is already installed."
    echo "Setting configuration of this script to squid."
    # Configure Squid
    sudo sed -i 's/http_port 3128/http_port 3128/' /etc/squid/squid.conf

    if [ $? -eq 0 ]; then
        echo "Squid was setup correctly."
    fi

    echo "Restarting Squid service."
    sudo systemctl restart squid
    if [ $? -eq 0 ]; then
        echo "Squid setup complete."
    fi

fi


if [[ $(ufw status | grep -w "Status: active") ]]; then
  echo "UFW firewall is already enabled."
  #Will add rules anyways even if the firewall is active
  echo "Adding rules."
 
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

users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

for user in "${users[@]}"; do
    # Check if user already exists
    if id -u "$user" &> /dev/null; then
        echo "User '$user' already exists. Checking Next User."

    else
        # Create user with home directory and bash shell
        sudo useradd -m -s /bin/bash "$user"
        echo "adding user $user..."

        # Generate random password using the built in automated password genrator built into the linux operating system
        password=$(apg -n 1 -m 10)

        # Set the generated password for the user
        echo "$user:$password" | sudo chpasswd

        #if the home directory for the user in the list doesn't have .ssh create it
        #I then set permissions so the user chan access the directory without issues
 
        if [ ! -d "/home/$user/.ssh" ]; then
            sudo -u "$user" mkdir "/home/$user/.ssh"
            sudo -u "$user" chmod 700 "/home/$user/.ssh"
        fi

        # Generate ssh keys for rsa if it dosn't exist for the user. 
        if [ ! -f "/home/$user/.ssh/id_rsa" ]; then
            sudo -u "$user" ssh-keygen -t rsa -b 4096 -f "/home/$user/.ssh/id_rsa" -q -N ""
        fi

        #generate ssh keys using ed25519 if it doesn't exist for the user
        if [ ! -f "/home/$user/.ssh/id_ed25519" ]; then
            sudo -u "$user" ssh-keygen -t ed25519 -f "/home/$user/.ssh/id_ed25519" -q -N ""
        fi

        # Add the generated public keys to authorized_keys file
        cat "/home/$user/.ssh/id_rsa.pub" >> "/home/$user/.ssh/authorized_keys"
        cat "/home/$user/.ssh/id_ed25519.pub" >> "/home/$user/.ssh/authorized_keys"
       
        # Set ownership and permissions for .ssh directory and authorized_keys file
        sudo chown -R "$user:$user" "/home/$user/.ssh"
        sudo chmod 600 "/home/$user/.ssh/authorized_keys"

        echo "User '$user' created successfully."
        echo "Password for '$user' is: $password"
    fi
done

for user in "${users[@]}"; do
    if [ "$user" = "dennis" ] && id -u "$user" &> /dev/null; then
        
        sudo usermod -aG sudo dennis

        if [ ! -d "/home/$user/.ssh" ]; then
            sudo -u "$user" mkdir "/home/$user/.ssh"
            sudo -u "$user" chmod 700 "/home/$user/.ssh"
        fi

        # Generate ssh keys for rsa if it dosn't exist for the user. 
        if [ ! -f "/home/$user/.ssh/id_rsa" ]; then
            sudo -u "$user" ssh-keygen -t rsa -b 4096 -f "/home/$user/.ssh/id_rsa" -q -N ""
            if [ $? -eq 0 ]; then
                echo "Made RSA key for Dennis"
            fi
        fi

        #generate ssh keys using ed25519 if it doesn't exist for the user
        if [ ! -f "/home/$user/.ssh/id_ed25519" ]; then
            sudo -u "$user" ssh-keygen -t ed25519 -f "/home/$user/.ssh/id_ed25519" -q -N ""
            if [ $? -eq 0 ]; then
                echo "Made ed25519 key for Dennis"
            fi
        fi

        # Add the generated public keys to authorized_keys file
        cat "/home/$user/.ssh/id_rsa.pub" >> "/home/$user/.ssh/authorized_keys"
        cat "/home/$user/.ssh/id_ed25519.pub" >> "/home/$user/.ssh/authorized_keys"
        #Give the key to dennis and append it to the file authorized_keys using the file path /home/dennis/.ssh/authorized_keys
        echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLnKfP0GSqbWSGYW/nC7UFLpfmgZTLUVlE2q1+jOHvDlUz+y0iCGdz+1WzILJeckv9EPaW1bVRLRuk1YQD9K7dGpXdRDM6Vt2g/EaQK+d+9L3aUhQj+6B3JlRGq+Yh0g/k0KvFCahUMyGNu47Vc6rHuKwM30be3Vi8biW1w/Sy2gGYevwM1byN3RkMDTy9LaLVf6OH9x/NM//xLJL5s6GjIKivAa3KBq63/3ZQZll3BlYp8bfwIFsKrBlLYW62UyrNG/ZiyL66XW6KlANMFg5/CQ3IvH/U9pQhStYP3p7PEKK5T4FS2trgsfU6JZxasufuK41UrYCDZ1FdMf user@example.com" >> "/home/dennis/.ssh/authorized_keys"
        if [ $? -eq 0 ]; then
            echo "Added Key to Dennis' key folder!"
        fi

    fi
done

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
        search: [home.arpa, localdomain]
"

new_netplan="/etc/netplan/new_netplan_config.yaml"

echo "$config" | sudo tee "$new_netplan" > /dev/null

sudo netplan apply &> /dev/null

if [ $? -eq 0 ]; then
    echo "Netplan configuration was applied!"
fi
