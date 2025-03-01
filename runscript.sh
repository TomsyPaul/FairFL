#! /bin/bash
#for i in `wc -l hostips`
size=`wc -l hostips | cut -d" " -f1`
coding=$1
epochs=$2
averager=$3
K=$4
runid=$5

cp partition_sizes partition_sizes_original

>nc_output.txt
nc -k -u -l 23432  >> nc_output.txt&

>nc_local_counts.txt
nc -k -u -l 23532  >> nc_local_counts.txt&

>nc_result.txt
nc -k -u -l 23632  >> nc_result.txt&

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

tar -cvzf files-to-upload.gz -T files-to-upload

i=0
while  read ip
do
 if [ ! -z $ip ]
 then
   if [ $coding == 'Y' ]
   then
      scp files-to-upload.gz tomsy@$ip:mydfl
      ssh -n tomsy@$ip docker cp /home/tomsy/mydfl/files-to-upload.gz c$i:/workspace/files-to-upload.gz
      ssh -n tomsy@$ip docker exec c$i tar -C /workspace/ -xz -f /workspace/files-to-upload.gz
   fi   
 ((i++))     	  
 fi
done < hostips

i=0
while  read ip
do
     if [ ! -z $ip ]
     then
        gnome-terminal --window -- bash -c "ssh -n tomsy@$ip docker exec c$i python find_local_count.py --rank=$i --size=$size --epochs=$epochs --averager=$averager --K=$K --runid=$runid --roundid=0; echo Output of $i; exec bash"   
        ((i++))     	
     fi
done < hostips

while [[ `cat nc_local_counts.txt | wc -l` < $size ]]
do
    sleep 1
    echo "nc_local_counts = `cat nc_local_counts.txt | wc -l`"
done
#read
#bash close-all-terminals.sh

i=0
while  read ip
do
     if [ ! -z $ip ]
     then
        gnome-terminal --window -- bash -c "ssh -n tomsy@$ip docker exec c$i python kld.py --rank=$i --size=$size --epochs=$epochs --averager=$averager --K=$K --runid=$runid --roundid=0; echo Output of $i; exec bash"   
        ((i++))     	
     fi
done < hostips



while [[ `cat nc_result.txt | wc -l` < $size ]]
do
    sleep 1
    echo "nc_result = `cat nc_result.txt | wc -l`"
done



sort -n -t"," -k2 nc_result.txt > sorted_result.txt
cat sorted_result.txt | cut -d"," -f2 > testout
for i in `cut sorted_result.txt -d"," -f1`
do 
head -n $((i+1)) hostips | tail -n 1
done > hostips_sorted

cumulative_size=0

rounds=`python3 generate_partitions.py --size=$size`
epochs=`echo $epochs/$rounds | bc`

for((x=0;x<rounds;x++))
do

   cp tempfile$x partition_sizes
   
   >files-to-upload
   echo layout-up >> files-to-upload
   echo layout-down >> files-to-upload
   #echo secrets >> files-to-upload
   echo keys >> files-to-upload
   echo run.py >> files-to-upload
   echo partition_sizes >> files-to-upload
   
   tar -cvzf files-to-upload.gz -T files-to-upload
   
   currentworldsize=`grep -o "," tempfile$x | wc -l`
   head -n $currentworldsize hostips_sorted > selected_from_sorted
   
   cumulative_size=$((cumulative_size+currentworldsize))
   
   #generate layouts
   python3 treegen.py --n=$currentworldsize
   #generate keys
   >keys
   keycount=`echo "$currentworldsize/4" |bc`
   for((i=0;i<$keycount;i++))
   do
     echo "$RANDOM" >> keys
   done
   
   i=0
   while  read ip
   do
     if [ ! -z $ip ]
     then
        if [ $coding == 'Y' ]
        then
                    j=`grep -n -w $ip hostips | cut -d ":" -f1`
                    scp files-to-upload.gz tomsy@$ip:mydfl
                    ssh -n tomsy@$ip docker cp /home/tomsy/mydfl/files-to-upload.gz c$((j-1)):/workspace/files-to-upload.gz
                    ssh -n tomsy@$ip docker exec c$((j-1)) tar -C /workspace/ -xz -f /workspace/files-to-upload.gz
       fi   
       ((i++))     	  
     fi
   done < selected_from_sorted
   
   ipoffirst=`head -n 1 selected_from_sorted`
   jfirst=`grep -n -w $ipoffirst hostips | cut -d ":" -f1`
   
   i=0
   while  read ip
   do
     if [ ! -z $ip ]
     then
        j=`grep -n -w $ip hostips | cut -d ":" -f1`
        gnome-terminal --window -- bash -c "ssh -n tomsy@$ip docker exec c$((j-1)) python run.py --rank=$i --size=$currentworldsize --epochs=$epochs --averager=$averager --K=$K --runid=$runid --roundid=$x --masteraddr=n$((jfirst-1)) --masterport=12${x}21; echo Output of $((j-1)); exec bash"   
        ((i++))     	
    fi
   done < selected_from_sorted
   
   echo "Completed Round $x"
   echo "Cumulative Size = $cumulative_size"
   
   while [[ `cat nc_output.txt | wc -l` < $cumulative_size ]]
   do
      sleep 2
      echo "nc_output count = `cat nc_output.txt | wc -l`"
   done
   read
done

read




cp partition_sizes_original partition_sizes

bash close-all-terminals.sh
