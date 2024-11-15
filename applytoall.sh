#! /bin/bash
i=0
while read ip
do
 if [ ! -z $ip ]
 then
   ssh tomsy@$ip $1 c$i </dev/null
   ((i++))     	
#   echo "id=$i, ip=$ip"
 fi
done < hostips
