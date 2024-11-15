#! /bin/bash
#for i in `wc -l hostips`
size=`wc -l hostips | cut -d" " -f1`
#((size++))

#start the containers
i=0
while  read ip
do
 if [ ! -z $ip ]
 then
   ssh tomsy@$ip docker start c$i </dev/null
   ((i++))     	
   #echo "id=$i, ip=$ip"
 fi
done < hostips

#execute torch run
i=0
while  read ip
do
 if [ ! -z $ip ]
 then
   if [ $i == "0" ]
   then
     gnome-terminal --window -x bash -c "ssh -n tomsy@$ip docker exec c0 torchrun --nnodes=$size --node_rank=0 --rdzv_id=456 --rdzv_backend=c10d --rdzv_endpoint=n0:1234 run.py ; exec bash"
      
   else
     leaderip=`ssh -n tomsy@172.16.89.5 docker exec c0 ifconfig | cut -d":" -f2 | grep inet | tr -s " " | cut -d" " -f3 | head -n 1 `
     gnome-terminal --window -x bash -c " ssh -n tomsy@$ip docker exec c$i torchrun --nnodes=$size --node_rank=$i --rdzv_id=456 --rdzv_backend=c10d --rdzv_endpoint=$leaderip:1234 run.py ; exec bash"
      
   fi
 ((i++))     	
     #echo "id=$i, ip=$line"
 fi
done < hostips

