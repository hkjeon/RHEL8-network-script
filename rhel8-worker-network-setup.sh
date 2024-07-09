#!/bin/bash

repo_ip=192.168.207.10

bond0_mem_1=eth1
#bond0_mem_1=ens10f0np0
#bond0_mem_2=ens10f1np1
bond0_mem_2=eth2
bond0_gw=192.168.213.1
bond0=(
192.168.213.14/26
192.168.213.15/26
192.168.213.16/26
192.168.213.17/26
192.168.213.18/26
192.168.213.19/26
192.168.213.20/26
192.168.213.21/26
192.168.213.22/26
)

bond1_mem_1=eth3
#bond1_mem_1=ens1f0
#bond1_mem_2=ens2f0
bond1_mem_2=eth4
bond1_vlan1_gw=10.10.157.1
bond1_vlan2_gw=10.10.154.1
bond1_vlan1=103
bond1_vlan2=104
bond1_103=(
10.10.157.14/26
10.10.157.15/26
10.10.157.16/26
10.10.157.17/26
10.10.157.18/26
10.10.157.19/26
10.10.157.20/26
10.10.157.21/26
10.10.157.22/26
)
bond1_104=(
10.10.154.14/26
10.10.154.15/26
10.10.154.16/26
10.10.154.17/26
10.10.154.18/26
10.10.154.19/26
10.10.154.20/26
10.10.154.21/26
10.10.154.22/26
)


wk_node_total="9"
wk_node_num="0"

#####################################################################
function set_network()
{
echo "select worker"
echo "============================"
while [ ${wk_node_num} -ne ${wk_node_total} ]
do
        wk_node_num=$((wk_node_num+1))
        echo " ${wk_node_num}) worker#${wk_node_num}"
done
echo " 0) quit"
echo "============================"
read -p "input number: " wk_num
echo

if [ ${wk_num} -eq 0 ]; then
        sleep 1
        exit
fi


wk_n=$((wk_num-1))
bond0_ip=${bond0[wk_n]}
bond1_vlan1_ip=${bond1_103[wk_n]}
bond1_vlan2_ip=${bond1_104[wk_n]}

echo " select worker node : worker${wk_num}"
echo " bond0 ip     : ${bond0_ip}"
echo " bond1.$bond1_vlan1 ip : ${bond1_vlan1_ip}"
echo " bond1.$bond1_vlan2 ip : ${bond1_vlan2_ip}"
echo " input enter"
read continue1
}

#####################################################################
function set_bond0()
{
echo
echo " << set bond0 network >>"
sleep 2

check_bond0=/proc/net/bonding/bond0

if [ -e ${check_bond0} ]; then
	echo
	echo "bond0 Interface exist.!"
	echo
else
nmcli con down $bond0_mem_1
nmcli con down $bond0_mem_2
nmcli con modify $bond0_mem_1 ipv4.method disable ipv6.method disable
nmcli con modify $bond0_mem_2 ipv4.method disable ipv6.method disable
nmcli con add type bond con-name bond0 ifname bond0 bond.options "mode=active-backup,miimon=100"
sleep 1

nmcli con add type ethernet slave-type bond con-name bond0-$bond0_mem_1 ifname $bond0_mem_1 master bond0
nmcli con add type ethernet slave-type bond con-name bond0-$bond0_mem_2 ifname $bond0_mem_2 master bond0
sleep 1

nmcli con modify bond0 ipv4.method manual ipv4.addresses "${bond0_ip}" ipv6.method disable ipv4.routes "192.168.0.0/16 $bond0_gw"
nmcli con up bond0
sleep 1

echo
echo "=========================================="
echo This is Bond0 IP Info.
echo "=========================================="
echo
ip -4 a | grep bond0
echo
sleep 4

echo
echo "=========================================="
echo This is Bond0 Interface Info.
echo "=========================================="
echo
ip link show | grep bond0
echo
sleep 4

echo
echo "=========================================="
echo This is Bond0 Routing Info.
echo "=========================================="
echo
ip route | grep bond0
echo
sleep 4
fi
}

#####################################################################
function set_bond1()
{
echo
echo " << set bond1 network >>"
sleep 2

check_bond1=/proc/net/bonding/bond1

if [ -e ${check_bond1} ]; then
	echo
        echo "bond1 Interface exist.!"
	echo
else
nmcli con down $bond1_mem_1
nmcli con down $bond1_mem_2
nmcli con modify $bond1_mem_1 ipv4.method disable ipv6.method disable
nmcli con modify $bond1_mem_2 ipv4.method disable ipv6.method disable
nmcli con add type bond con-name bond1 ifname bond1 bond.options "mode=active-backup,miimon=100"
nmcli con modify bond1 ipv4.method disable ipv6.method disable
sleep 1

nmcli con add type ethernet slave-type bond con-name bond1-$bond1_mem_1 ifname $bond1_mem_1 master bond1
nmcli con add type ethernet slave-type bond con-name bond1-$bond1_mem_2 ifname $bond1_mem_2 master bond1
nmcli con add type vlan con-name bond1.$bond1_vlan1 ifname bond1.$bond1_vlan1 vlan.parent bond1 vlan.id $bond1_vlan1
nmcli con add type vlan con-name bond1.$bond1_vlan2 ifname bond1.$bond1_vlan2 vlan.parent bond1 vlan.id $bond1_vlan2
sleep 1

nmcli con modify bond1.$bond1_vlan1 ipv4.method manual ipv4.addresses "${bond1_vlan1_ip}" ipv6.method disable ipv4.gateway $bond1_vlan1_gw
nmcli con modify bond1.$bond1_vlan2 ipv4.method manual ipv4.addresses "${bond1_vlan2_ip}" ipv6.method disable ipv4.routes "10.10.154.64/26 $bond1_vlan2_gw" 
nmcli con up bond1
nmcli con up bond1.$bond1_vlan1
nmcli con up bond1.$bond1_vlan2

echo
echo "=========================================="
echo This is Bond1 IP Info.
echo "=========================================="
echo
ip -4 a | grep bond1
echo
sleep 4

echo
echo "=========================================="
echo This is Bond1 Routing Info.
echo "=========================================="
echo
ip route | grep bond1
echo
sleep 4
fi
}

#####################################################################
function bonding_test()
{
sudo ifenslave -c bond0 $bond0_mem_1
echo
echo "=========================================="
echo Now Bond0 $(cat /proc/net/bonding/bond0 | grep Active)
echo "=========================================="
echo
ping -c 3 $bond0_gw
ping -c 3 $repo_ip
sudo ifenslave -c bond0 $bond0_mem_2
echo
echo "=========================================="
echo Now Bond0 $(cat /proc/net/bonding/bond0 | grep Active)
echo "=========================================="
echo
ping -c 3 $bond0_gw
ping -c 3 $repo_ip
sudo ifenslave -c bond0 $bond0_mem_1
sleep 2

sudo ifenslave -c bond1 $bond1_mem_1
echo
echo "=========================================="
echo Now Bond1 $(cat /proc/net/bonding/bond1 | grep Active)
echo "=========================================="
echo
ping -c 3 $bond1_vlan1_gw
ping -c 3 $bond1_vlan2_gw
sudo ifenslave -c bond1 $bond1_mem_2
echo
echo "=========================================="
echo Now Bond1 $(cat /proc/net/bonding/bond1 | grep Active)
echo "=========================================="
echo
ping -c 3 $bond1_vlan1_gw
ping -c 3 $bond1_vlan2_gw
sudo ifenslave -c bond1 $bond1_mem_1
sleep 2
}

#####################################################################
function set_sshd()
{
sudo sed -i -e '/#UseDNS/ c\UseDNS no' /etc/ssh/sshd_config
sudo systemctl restart sshd
sleep 3
sudo systemctl status sshd | grep Active
}

#####################################################################
set_check()
{
	set_network
	set_bond0
	set_bond1
	bonding_test
	set_sshd
}

#####################################################################
usage()
{
	echo "Usage   : rhel-worker-network-setup.sh [--all | --net | --test] "
	echo "Options : \"--all\" will All network setup and then Ping check with bondind switchover"
	echo "          \"--net\" will Network setup with bond and vlan"
        echo "          \"--test\" will Gateway ping check with bonding switchover"
        echo "          \"--help\" show this help screen"
}

if [ "$#" -lt 1 ]; then
        usage
else
        case $1 in
		"--all" )
			set_check
		;;
                "--net" )
		        set_network
			set_bond0
			set_bond1
                ;;
                "--test" )
                        bonding_test
                ;;
                "--repo" )
                        set_repo
                ;;
                "--help" )
                        usage
                        exit
                ;;
        esac
fi

