#! /bin/bash
#add host to swarm
#setting passwordless ssh
#add user to docker group
#create container
i=0
while read ip
do
 if [ ! -z $ip ]
 then
   ssh tomsy@$ip "docker create -it --net test-net --hostname n$i  --name c$i 9446917617/mydfl-image:pytorch-docker" </dev/null
   ((i++))     	
#   echo "id=$i, ip=$ip"
 fi
done < hostips
