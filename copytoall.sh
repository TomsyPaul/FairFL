#! /bin/bash
i=1
while read ip
do
 if [ ! -z $ip ]
 then
   scp $1 tomsy@$ip:mydfl </dev/null
   ((i++))     	
#   echo "id=$i, ip=$ip"
 fi
done < hostips
