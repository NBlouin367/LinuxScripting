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
    sudo apt-get install -y openssh-server > /dev/null
    if [ $? -eq 0 ]; then
        echo "openssh install complete."
    fi

    # Configure SSH server
    sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo sed -i 's/PubkeyAuthentication no/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    echo "Restarting services."
    sudo systemctl restart sshd
    if [ $? -eq 0 ]; then
        echo "SSH Setup complete.."
    fi
else
    echo "SSH server is already installed."
    echo "Going to apply this scripts config for SSH"
    # Configure SSH server
    sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo sed -i 's/PubkeyAuthentication no/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    echo "Restarting services."
    sudo systemctl restart sshd
    if [ $? -eq 0 ]; then
        echo "SSH setup Complete."

fi

dpkg -s apache2 &> /dev/null
if [ $? -ne 0 ]; then
    echo "Installing Apache2 web server..."
    sudo apt-get install -y apache2 > /dev/null

    if [ $? -eq 0 ]; then
        echo "Installed Apache2."
    fi

    # Configure Apache2

    sudo a2enmod ssl

    if [ $? -eq 0 ]; then
        echo "a2enmod success."
    fi

    echo "Restarting Apache2 to complete setup."
    sudo systemctl restart apache2
    if [ $? -eq 0 ]; then
        echo "Apache setup complete."
    fi

else
    echo "Apache2 web server is already installed."
    echo "Will apply settings to apache from this script."
    sudo a2enmod ssl

    if [ $? -eq 0 ]; then
        echo "a2enmod success."
    fi

    echo "Restarting Apache2 to complete setup."
    sudo systemctl restart apache2
    if [ $? -eq 0 ]; then
        echo "Apache setup complete."
    fi

fi

dpkg -s squid &> /dev/null
if [ $? -ne 0 ]; then
    echo "Installing Squid web proxy..."
    sudo apt-get install -y squid > /dev/null
    # Configure Squid
    sudo sed -i 's/http_port 3128/http_port 3128/' /etc/squid/squid.conf
    echo "restarting Squid service."
    sudo systemctl restart squid
    if [ $? -eq 0 ]; then
        echo "Squid setup Complete."
    fi
else
    echo "Squid web proxy is already installed."
    echo "Setting configuration of this script to squid."
    # Configure Squid
    sudo sed -i 's/http_port 3128/http_port 3128/' /etc/squid/squid.conf
    echo "restarting Squid service."
    sudo systemctl restart squid
    if [ $? -eq 0 ]; then
        echo "Squid setup Complete."
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
    if id -u "$user" >/dev/null 2>&1; then
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
    if [ "$user" = "dennis" ] && id -u "$user" > /dev/null 2>&1; then
        
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
