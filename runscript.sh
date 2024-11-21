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
   gnome-terminal --window -- bash -c "ssh -n tomsy@$ip docker exec c$i python run.py --rank=$i --size=$size; echo Output of $i; exec bash"   
 ((i++))     	
 fi
done < hostips

