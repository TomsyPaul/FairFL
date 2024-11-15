#! /bin/bash
i=0
while read ip
do
 if [ ! -z $ip ]
 then
   gnome-terminal --window -x bash -c "./buildcommand.sh $ip; exec bash" 
   ((i++))     	
#   echo "id=$i, ip=$ip"
 fi
done < hostips
