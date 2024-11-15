#! /bin/bash
#for i in `wc -l hostips`
size=`wc -l hostips`
((size++))

#start the containers
i=0
while  read ip
do
 if [ ! -z $ip ]
 then
   ssh tomsy@$ip docker start -i -a c$i
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
     ssh tomsy@$ip docker exec c0 torchrun --nnodes=$size --node_rank=0 --rdzv_id=456 --rdzv_backend=c10d --rdzv_endpoint=n0:1234 run.py
   else
     ssh tomsy@$ip docker exec c$i sed -i -e "s/size\ =\ SIZE/size\ =\ $size/g" -e "s/rank=RANK/rank=$i/g" run1.py
leaderip=`ssh tomsy@172.16.89.5 docker exec c0 ifconfig | cut -d":" -f2 | grep inet | tr -s " " | cut -d" " -f3 | head -n 1`
     ssh tomsy@$ip docker exec c$i torchrun --nnodes=$size --node_rank=$i --rdzv_id=456 --rdzv_backend=c10d --rdzv_endpoint=$leaderip:1234 run1.py
     ((i++))     	
     #echo "id=$i, ip=$line"
   fi
 fi
done < hostips

