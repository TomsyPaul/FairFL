#! /bin/bash
#for i in `wc -l hostips`
size=`wc -l hostips | cut -d" " -f1`
coding=$1
epochs=$2
averager=$3
K=$4
runid=$5

>nc_output.txt
nc -k -u -l 23432  >> nc_output.txt&

>nc_local_counts.txt
nc -k -u -l 23532  >> nc_local_counts.txt&

>nc_global_counts.txt
nc -k -u -l 23632  >> nc_global_counts.txt&

python3 treegen.py --n=$size

>keys
keycount=`echo "$size/4" |bc`
for((i=0;i<$keycount;i++))
   do
     echo "$RANDOM" >> keys
   done

#set files to upload
>files-to-upload
echo layout-up >> files-to-upload
echo layout-down >> files-to-upload
echo keys >> files-to-upload
echo find_local_count.py >> files-to-upload
echo kld.py >> files-to-upload
#echo run.py >> files-to-upload
echo partition_sizes >> files-to-upload

i=0
while  read ip
do
 if [ ! -z $ip ]
 then
   if [ $coding == 'Y' ]
   then
   while read filename
   do
      scp $filename tomsy@$ip:mydfl
      ssh -n tomsy@$ip docker cp /home/tomsy/mydfl/$filename c$i:/workspace/$filename
   done < files-to-upload      
   fi   
 ((i++))     	  
 fi
done < hostips

i=0
while  read ip
do
     if [ ! -z $ip ]
     then
        gnome-terminal --window -- bash -c "ssh -n tomsy@$ip docker exec c$i python find_local_count.py --rank=$i --size=$size --epochs=$epochs --averager=$averager --K=$K --runid=$runid --round=0; echo Output of $i; exec bash"   
        ((i++))     	
     fi
done < hostips

while [[ `cat nc_local_counts.txt | wc -l` < $size ]]
do
    sleep 1
    echo "nc_local_counts = `cat nc_local_counts.txt | wc -l`"
done

bash close-all-terminals.sh

i=0
while  read ip
do
     if [ ! -z $ip ]
     then
        gnome-terminal --window -- bash -c "ssh -n tomsy@$ip docker exec c$i python kld.py --rank=$i --size=$size --epochs=$epochs --averager=$averager --K=$K --runid=$runid --round=0; echo Output of $i; exec bash"   
        ((i++))     	
     fi
done < hostips



while [[ `cat nc_global_counts.txt | wc -l` < $size ]]
do
    sleep 1
    echo "nc_global_counts = `cat nc_global_counts.txt | wc -l`"
done
bash close-all-terminals.sh
