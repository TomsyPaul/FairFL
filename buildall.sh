#! /bin/bash
i=0
while read ip
do
 if [ ! -z $ip ]
 then
   gnome-terminal --window -- bash -c "./buildcommand.sh $ip $1; exec bash" 
   ((i++))     	
#   echo "id=$i, ip=$ip"
 fi
done < hostips
