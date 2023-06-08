#!/bin/bash

#Assignment 1: System Report
#Name:  Nicolas Blouin
#Student Number: 200410446

#Script Description

#Write something here to describe my script

#Top of the script variables, I am storing the current USER on the system into
#a variable called my_username for future use. I also am storing the current date
#with a few options such as %A which will give me the full weekday name.

username=$USER
date=$(date +"%A, %B %d, %Y %T")


hostname=$(hostname)
source /etc/os-release
uptime=$(uptime -p)

cpu=$(lshw -class processor | grep "product:" | awk -F "product: " '{print $2}' | sort -u)

#

current_cpu_mhz=$(lscpu | grep "MHz" | awk '{print $3}')
#
maximum_cpu_mhz=$(lscpu | grep "CPU max MHz" | awk '{print $4}')
ram=$(free -h | grep "Mem: " | awk '{print $2}')
disks=$(lsblk -o NAME,MODEL,SIZE | grep -v "loop")
videocard=$(lspci | grep -E "VGA|3D"| awk -F ": " '{print $2}' | sort -u)

fqdn=$(hostname -f)
host_ip_address=$(hostname -I | awk '{print $1}')
default_gateway=$(ip r | grep "default via" | awk '{print $3}')
dns_server=$(cat /etc/resolv.conf | grep "nameserver" | awk '{print $2}')

list_of_users=$(who -u | awk '{print $1}' | tr '\n' ',')
free_disk_space=$(df -h | awk '{print $1, $4}' | column -t)
number_of_processes=$(ps -e --no-header | wc -l)
load_averages=$(uptime | grep "load average: " | awk '{print $8, $9, $10}')
memory_allocation=$(free -h -t)

cat << EOF

====================================================

Script Description:

This script will create a system information report
including system hardware, network, and system status
of the current machine.

Some of the Commands inside this Script 
Require Permissions. This script should be run with 
sudo to ensure complete command output 

====================================================

System Report Generated by: $username

Date & Time of Report: $date

====================================================

System Information:
-------------------

The Current Hostname: $hostname

OS: $NAME $VERSION

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

EOF
