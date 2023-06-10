#!/bin/bash

#Assignment 1: System Report
#Name: Nicolas Blouin
#Student Number: 200410446

#Script Description:
#This script works by taking the filtered output of commands
#and storing them into variables, I then use the variables throughout my script
#to display information about the system the script is being ran on. 


#I am storing the current USER on the system into
#a variable called my_username for future use.

username=$USER

#I am storing the current date with a few options such as %A which will
#give me the full weekday name. I used a few more options to display in my prefered format.

date=$(date +"%A, %B %d, %Y %T")

#I store the system variable $(hostname) into my own variable called hostname.

hostname=$(hostname)

#I created a source so that I can easily access the variable label names
#inside this path such as the operating System name/version.

source /etc/os-release

#I store the uptime -p command into variable called uptime
#Using the -p option will display the uptime in pretty format
#enabling more readable text on the screen.

uptime=$(uptime -p)

#I created a cpu variable and store a lshw command into it 
#I used -class processor options to filter the data of the lshw command
#followed by piping into grep and looking for product
#once product was found, I used awk -F to specify my separation area
#once I had my reference point I used print $2 to get the 2nd field of data from that 
#area, I then sorted using -u to find unique items and no duplicates.

cpu=$(lshw -class processor | grep "product:" | awk -F "product: " '{print $2}' | sort -u)

#Created a current cpu mhz variable to store my command output
#by using the lscpu command I can then filter using grep
#I can specify CPU MHz which is the label for the current speed
#this will filter this line only for my output later.

current_cpu_mhz=$(lscpu | grep "CPU MHz")

#created a variable for maximum cpu mhz and store my output into it
#By using the lscpu command I can list out CPU information
#once then using pipe into grep I retrieve the label with 
#CPU max MHz which will filter my output to give me the.
#max speed of the CPU

maximum_cpu_mhz=$(lscpu | grep "CPU max MHz")

#Storing a command into variable called ram. I used the free command 
#to gather information on the vailable RAM within the system 
#I also used the -h option to make sure the info is
#human readable. I then piped this into grep and searched for matches
#of Mem: , I was able to then use awk to pull the data from this line using 
#print $2 gathering the 2nd field of information which was total RAM.

ram=$(free -h | grep "Mem: " | awk '{print $2}')

#Storing a command into a variable called disks. I used lsblk
#to find all the information on the block devices
#using the -o I was able to filter the specific columns of data
#I only needed the name, model, and make. I then used grep -v to remove
#all occurences of loop which was appearing in my original output.

disks=$(lsblk -o NAME,MODEL,SIZE | grep -v "loop")

#I made a command and stored it into a variable called videocard
#using the lspci command, I was able to find any PCIe expansion devices
#since video cards are in these slots, I then grep and search for VGA or 3D
#as these are common names withing these device names.
#Once a device is found with these parameters I use awk to find the semicolon
#and go 2 fields from that point. this gave me the video adapter portion 
#I then sorted the entire output using sort -u to find all unique output and no duplicates.

videocard=$(lspci | grep -E "VGA|3D"| awk -F ": " '{print $2}' | sort -u)

#I stored a command into a variable called fqdn for the Fully Qualified Domain Name
#Using hostname with the -f option I am able to find out the FQDN of the host machine.

fqdn=$(hostname -f)

#I stored the output of my hostname command into a variable called host_ip_address
#in this command I used hostname with the option of -I to give me the address of the host PC
#I then piped to awk and used print $1 to get the first item in the list of addresses.

host_ip_address=$(hostname -I | awk '{print $1}')

#I created a variable called default_gateway and stored a command out into it
#the command I used was ip r which shows the routes of the machine
#I then grep for the keyword default via, which is the default gateway address line
#I then piped to awk and got the 3rd field in the line which was the IP address.

default_gateway=$(ip r | grep "default via" | awk '{print $3}')

#Created a command called dns_server and stored my command output into it
#I cat the /etc/resolve.conf file to read its contents. This file contains DNS information
#by using grep I was able to filter for my nameserver, I then used awk to capture only the address portion 
#then using head with a value of -1 I can gather the first entry in the list which.
#will be my host machines DNS address.

dns_server=$(cat /etc/resolv.conf | grep "nameserver" | awk '{print $2}' | head -1)

#Interface Commands
#made an interface name command that uses the lshw command with -class to filter 
#for network info only, I then pipe to a grep to match logical name, this will give me the 
#interfaces name lines, I then use awk to print out only the 3rd field which what the interface
#then using head -1 I retrieve only the first  entry to my output which will be my main interface.

interface_name=$(lshw -class network | grep "logical name:" | awk '{print $3}' | head -1)

#I made a variable called interface make to store my output of the command into.
#I used lshw with -class network to filter only network information. I then used awk -F
#to find the vendor: portion of lshw command and then print $2 to go 2 field from the vendor:
#area, I then used sort -u for unique to filter out any duplicates 

interface_make=$(lshw -class network | awk -F "vendor:" '{print $2}' | sort -u)

#I made a variable called interface model and store my command output into it
#I used lshw with -class network to find only network information in the output.
#then using awk -F I looked for product: which was one of the labels in the lshw -class network output
#after finding the product: position, I used print $2 to go 2 field from that position which gave the 
#full model name output, I then sorted using sort -u to filter duplicates.

interface_model=$(lshw -class network | awk -F "product:" '{print $2}' | sort -u)

#Using the ip command -o makes the ip command output to one line in parsable format, I then using the
#-4 option to filter only ipv6 addresses from the command, then using primary to make sure only 
#the primary addresses are displayed, then the scope filter global finds the main IP address on the system
#that have global reach meaning connection to other devices. I then use awk to print out the 4th field
#which had the address and the / subnet prefix on it. I then used head -1 to filter for the first entry 
#this being my main address associated with my main interface. 

ip_address_cidr=$(ip -o -4 addr show primary scope global | awk '{print $4}' | head -1)

#I store a command output into a variable list_of_users
#the purpose of this command is to use the who command with option -u to list the current
#users logged in, I then use awk to gather the first entry which is the users name on the line
#I piped the entire output to a replace that will remove newlines and just put a comma instead
#this will format the users in an organized list.

list_of_users=$(who -u | awk '{print $1}' | tr '\n' ',')

#I created a variable called free_disk_space and stored my command output into it
#I used the df command with the -h option to display disk information in human readable format
#i then used awk print $1, $4 to print out only columns 1 and 4 which has the file system and available space columns
#I then pipe to a column command which formats my output to be clean and doesn't smush columns.

free_disk_space=$(df -h | awk '{print $1, $4}' | column -t)

#I created a variable called number_of_proccesses and stored my commands output into it
#to gather the number of running proccesses I used the ps commands to list the processes
#I used the -e option to list every process and I used the --no-header option to remove the headers section of output
#I was then able to use a pipe and use the word count command on my ps information. I used the -l option to make it count every line
#the number of lines counted is the # of proccess so that's what gets displayed. 

number_of_processes=$(ps -e --no-header | wc -l)

#I store the commands output into a variable called load_averages
#I used the uptime command as it displays this information
#I then used grep to match load average, followed by an awk to print the
#specific fields I wanted, fields 8 9 , and 10 had the load average values so I awk'd them.

load_averages=$(uptime | grep "load average: " | awk '{print $8, $9, $10}')

#I stored my output of this command into a variable called memory_allocation
#using the free command I am able to retrieve information on RAM. using the -h option
#it will display my output in human readable values and the -t option will output the total 
#memory value also. 

memory_allocation=$(free -h -t)

#I made a variable called listening_network_ports and stored my command into it
#the command i used is ss and it diplays  network socket information
#I used the -l option to output listening ports, I then used -n to
#output the port numbers in numeric format instead of the service name
#lastly, I filter out a majority of the ports using -t to find only tcp ports.

listening_network_ports=$(ss -l -n -t)

#lastly, I made a variable called firewall_rules. I used the command
#ufw to display firewall information. I included a few options such as status 
#which will display if the firewall is active as well as rules. I also included the
#verbose option to give more output of the ufw command.

firewall_rules=$(ufw status verbose)

#Setting the beginning of my file using a cat until it hits the end of file.

cat << EOF

====================================================

Script Description:

This script will create a system information report
including system hardware, network, and system status
of the current machine.

Some of the Commands inside this Script 
Require Permissions. This script should be run with 
sudo to ensure complete command output. 

====================================================

System Report Generated by: $username

Date & Time of Report: $date

====================================================

System Information:
-------------------

The Current Hostname: $hostname

Operating System: $NAME $VERSION

System Uptime: $uptime

====================================================

Hardware Information:
---------------------

CPU: $cpu

Current CPU Speed (MHz): $current_cpu_mhz

Maximum CPU Speed (MHz): $maximum_cpu_mhz

Total Memory (RAM): $ram

Installed Storage Disks:

$disks

Video Card: $videocard

====================================================

Network Information:
--------------------

FQDN: $fqdn

Host IP Address: $host_ip_address

Default Gateway: $default_gateway

DNS Server: $dns_server

Interface Information:

Interface Name: $interface_name

Interface Make: $interface_make

Interface Model: $interface_model

IP Address CIDR: $ip_address_cidr

====================================================

System Status:
--------------

Users Logged In: $list_of_users

Free Disk Space:

$free_disk_space

Processes Running (#): $number_of_processes

Load Averages (1 Min, 5 Min, 15 Min): $load_averages

Memory Allocation: 

$memory_allocation

Listening Network Ports:

$listening_network_ports

Firewall Rules:

$firewall_rules


EOF
