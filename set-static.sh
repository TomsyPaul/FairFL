#! /bin/bash
starting_ip=172.16.64.31
num_hosts=16

i=31
cat<<<"network:
  version: 2
  renderer: NetworkManager
  ethernets:
   eno1:
     dhcp4: false
     dhcp6: false
     addresses: [172.16.64.this_ip/22]
     routes:
      - to: default
        via: 172.16.64.1
     nameservers:
         addresses: [10.0.0.2,10.0.0.3]" > template_file_original
cat<<<"#! /bin/bash
cp /etc/netplan/50-cloud-init.yaml .
rm /etc/netplan/50-cloud-init.yaml
cp template_file /etc/netplan/01-network-manager-all.yaml
netplan apply">make_static.sh
cat<<<"#! /bin/bash
cp /etc/netplan/01-network-manager-all.yaml .
rm /etc/netplan/01-network-manager-all.yaml
cp 50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml
netplan apply">make_dhcp.sh
while read ip
do
  cp template_file_original template_file
  sed -i -e 's\this_ip\'$i'\g' template_file         
  scp template_file tomsy@$ip:
  scp make_static.sh tomsy@$ip:
  scp make_dhcp.sh tomsy@$ip:
  ((i++))     	
done < hostips
rm template_file_original
rm template_file
rm make_static.sh
rm make_dhcp.sh

