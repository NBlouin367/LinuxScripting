#!/bin/bash
# This script creates a virtual network suitable for learning about networking
# created by dennis simpson 2023, all rights reserved

lannetnum="192.168.16"
mgmtnetnum="172.16.1"
prefix=target
startinghostnum=10
remoteadmin="remoteadmin"
numcontainers=2

# allow choices on the command line
while [ $# -gt 0 ]; do
    case "$1" in
        --help | -h )
            echo "
Usage: $(basename $0) [-h | --help] [--fresh] [--prefix targetnameprefix] [--user remoteadminaccountname] [--lannet A.B.C] [--mgmtnet A.B.C] [--count N] [--hostnumbase N]
This script sets up a private network using containers in a Ubuntu hosting machine for educational purposes.
It has an OpenWRT router connecting the hosting OS lan to its wan interface, and 2 virtual networks called lan and mgmt on additional interfaces.
Will install and initialize lxd if necessary.
Will create lan and mgmt virtual networks if necessary using host 2 on each network for the router, both using /24 mask.
Will create openwrt router with lxdbr0 for WAN, lan for lan, and mgmt for private management network.
Creates target containers, named using target name prefix with the container number appended.
Creates a remote admin account with sudo privilege, no passwd access, and ssh access for the user who runs this script.
Adds host names with IP addresses to /etc/hosts inside the containers and in the hosting OS.
The hosting OS will have direct access to all the virtual networks using host number 1.
Defaults
fresh:       false
prefix:      target
user:        remoteadmin
lannet:      192.168.16
mgmtnet:     172.16.1
hostnumbase: 10
count:       2
"
            exit
            ;;
        --fresh )
	    targets=$(lxc list|grep -o -w target.)
            for target in $targets; do
                lxc delete $target --force
            done
            lxc delete openwrt --force
            lxc network delete lan
            lxc network delete mgmt
            ;;
        --prefix )
            if [ -z "$2" ]; then
                echo "Need a hostname prefix for the --prefix option"
                exit 1
            else
                prefix="$2"
                shift
            fi
            ;;
        --user )
            if [ -z "$2" ]; then
                echo "Need a username for the --user option"
                exit 1
            else
                remoteadmin="$2"
                shift
            fi
            ;;
        --lannet )
            if [ -z "$2" ]; then
                echo "Need a network number in the format N.N.N for the --lannet option"
                exit 1
            else
                lannetnum="$2"
                shift
            fi
            ;;
        --mgmtnet )
            if [ -z "$2" ]; then
                echo "Need a network number in the format N.N.N for the --mgmtnet option"
                exit 1
            else
                mgmtnetnum="$2"
                shift
            fi
            ;;
        --count )
            if [ -z "$2" ]; then
                echo "Need a number for the --count option"
                exit 1
            else
                numcontainers="$2"
                shift
            fi
            ;;
        --hostnumbase )
            if [ -z "$2" ]; then
                echo "Need a number for the --hostnumbase option"
                exit 1
            else
                startinghostnum="$2"
                shift
            fi
            ;;
    esac
    shift
done

# install lxd and initialize if needed
lxc --version >&/dev/null || sudo apt install lxd || snap install lxd || exit 1
if ! ip a s lxdbr0 >&/dev/null; then
    sudo lxd init --auto
fi
if ! ip a s lan >&/dev/null; then
    lxc network create lan ipv4.address=$lannetnum.1/24 ipv6.address=none ipv4.dhcp=false ipv6.dhcp=false ipv4.nat=false
fi
if ! ip a s mgmt >&/dev/null; then
    lxc network create mgmt ipv4.address=$mgmtnetnum.1/24 ipv6.address=none ipv4.dhcp=false ipv6.dhcp=false ipv4.nat=false
fi

#create the router container if necessary
if ! lxc info openwrt >&/dev/null ; then
    lxc launch images:openwrt/22.03 openwrt -n lxdbr0
    lxc network attach lan openwrt eth1
    lxc network attach mgmt openwrt eth2
    lxc exec openwrt -- sh -c 'echo "
config device
    option name 'eth1'

config interface 'lan'
    option device 'eth1'
    option proto 'static'
    option ipaddr '192.168.16.2'
    option netmask '255.255.255.0'
    
config device
    option name 'eth2'

config interface 'private'
    option device 'eth2'
    option proto 'static'
    option ipaddr '172.16.1.2'
    option netmask '255.255.255.0'

" >>/etc/config/network'
    lxc exec openwrt reboot
fi

# we want $numcontainers containers running
numexisting=$(lxc list -c n --format csv|grep $prefix| wc -l)
for (( n=0;n<numcontainers - numexisting;n++ )); do
    container="$prefix$((n+1))"
    if lxc info $container >& /dev/null; then
        echo "$container already exists"
        continue
    fi
    containerlanip="$lannetnum.$((n + startinghostnum))"
    containermgmtip="$mgmtnetnum.$((n + startinghostnum))"
	lxc launch ubuntu:lts $container -n lan
    lxc network attach mgmt $container eth1
    lxc exec $container -- sh -c "cat > /etc/netplan/50-cloud-init.yaml <<EOF
network:
    version: 2
    ethernets:
        eth0:
            addresses: [$containerlanip/24]
            routes:
              - to: default
                via: $lannetnum.2
            nameservers:
                addresses: [$lannetnum.2]
                search: [home.arpa, localdomain]
        eth1:
            addresses: [$containermgmtip/24]
EOF
"
    lxc exec $container -- sh -c 'echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg'
    while ! lxc exec $container -- systemctl is-active --quiet ssh; do sleep 1; done
    lxc exec $container netplan apply
    lxc exec $container -- sh -c "echo $containerlanip $container >>/etc/hosts"
    lxc exec $container -- sh -c "echo $containermgmtip $container-mgmt >>/etc/hosts"
    
    echo "Adding SSH host key for $container"
    
    [ -d ~/.ssh ] || ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -q -N ""
    [ ! -f ~/.ssh/id_ed25519.pub ] && ssh-keygen -t ed25519 -f id_ed25519 -q -N ""
    ssh-keygen -q -R $container 2>/dev/null >/dev/null
    ssh-keyscan -t ed25519 $container >>~/.ssh/known_hosts 2>/dev/null
    ssh-keygen -q -H >/dev/null 2>/dev/null

    echo "Adding remote admin user '$remoteadmin' to $container"
    lxc exec $container -- useradd -m -c "SSH remote admin access account" -s /bin/bash -o -u 0 $remoteadmin
    lxc exec $container mkdir /home/$remoteadmin/.ssh
    lxc exec $container chmod 700 /home/$remoteadmin/.ssh
    lxc file push ~/.ssh/id_ed25519.pub $container/home/$remoteadmin/.ssh/
    lxc exec $container cp /home/$remoteadmin/.ssh/id_ed25519.pub /home/$remoteadmin/.ssh/authorized_keys
    lxc exec $container chmod 600 /home/$remoteadmin/.ssh/authorized_keys
    lxc exec $container -- chown -R $remoteadmin /home/$remoteadmin

    echo "Setting $container hostname"
    lxc exec $container hostnamectl set-hostname $container
    lxc exec $container reboot
    
    echo "Adding $container to /etc/hosts file"
    sudo sed -i -e "/ $container\$/d" -e "/ $container-mgmt\$/d" /etc/hosts
    sudo sed -i -e '$a'"$containerlanip $container" -e '$a'"$containermgmtip $container-mgmt" /etc/hosts

done

