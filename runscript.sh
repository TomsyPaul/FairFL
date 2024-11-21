#! /bin/bash
#for i in `wc -l hostips`
size=`wc -l hostips | cut -d" " -f1`
#((size++))

#execute torch run
i=0
while  read ip
do
 if [ ! -z $ip ]
 then
   if [ $i == "0" ]
   then
     gnome-terminal --window -x bash -c "ssh -n tomsy@$ip docker exec c0 python run.py --rank=0 --size=$size; exec bash"
   else
#     leaderip=`ssh -n tomsy@172.16.89.5 docker exec c0 ifconfig | cut -d":" -f2 | grep inet | tr -s " " | cut -d" " -f3 | head -n 1 `
#     echo "Leader IP = $leaderip"
     if [ $i == "1" ]
     then 
        sleep 1
     fi   
     gnome-terminal --window -x bash -c "ssh -n tomsy@$ip docker exec c$i python run1.py --rank=$i --size=$size; exec bash"   
   fi
 ((i++))     	
     #echo "id=$i, ip=$line"
 fi
done < hostips

