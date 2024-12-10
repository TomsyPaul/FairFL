#! /bin/bash
j=0
for i in `cat hostips`
do ssh tomsy@$i 'docker exec ' c$j $1  < /dev/null 
((j++))
done
