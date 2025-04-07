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
echo find_local_count.py >> files-to-upload
echo kld.py >> files-to-upload
echo partition_sizes >> files-to-upload
echo run.py >> files-to-upload

tar -cvzf files-to-upload.gz -T files-to-upload
#echo keys >> files-to-upload
#echo partition_sizes >> files-to-upload

#>partition_sizes
#for((i=0;i<$size;i++))
#do
# common=`echo 1.0/$size | bc -l`
# common=`echo 1.0/16 | bc -l`
# echo -n "$common, ">>partition_sizes 
#done   

cumulative_size=0

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
        gnome-terminal --window -- bash -c "ssh -n tomsy@$ip docker exec c$i python find_local_count.py --rank=$i --size=$size --epochs=$epochs --averager=$averager --K=$K --runid=$runid --roundid=0; echo Output of $i"   
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
        gnome-terminal --window -- bash -c "ssh -n tomsy@$ip docker exec c$i python kld.py --rank=$i --size=$size --epochs=$epochs --averager=$averager --K=$K --runid=$runid --roundid=0; echo Output of $i"   
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
   echo partition_sizes >> files-to-upload
   
   currentworldsize=`grep -o "," tempfile$x | wc -l`
   head -n $currentworldsize hostips_sorted > selected_from_sorted
   
   cumulative_size=$((cumulative_size+currentworldsize))
   
   tar -cvzf files-to-upload.gz -T files-to-upload
   
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
#   read
   
   echo "$currentworldsize,$2,$3,$K,$runid,$x" > "results/$currentworldsize-$averager-$epochs-$runid-$x"
   echo -e "******************\n" >> "results/$currentworldsize-$averager-$epochs-$runid-$x"
   bash applytoallcontainers.sh "cat /logs/$currentworldsize-$averager-$epochs-$runid-$x;echo" >> "results/$currentworldsize-$averager-$epochs-$runid-$x"
   echo -e "Result..\n"
   cat results/$currentworldsize-$averager-$epochs-$runid-$x
   echo "$currentworldsize,$2,$3,$K,$runid,$x" >> "results/summary"
   grep TIME results/$currentworldsize-$averager-$epochs-$runid-$x | cut -d"," -f6 | awk '{ sum += $1; n++ } END { if (n > 0) print "Average time taken = " sum / n "\n"; }' >> results/summary
   echo -e "Average Loss\n" >> "results/summary"
   for((i=0;i<$epochs;i++))
   do 
      grep "epoch,$i" results/$currentworldsize-$averager-$epochs-$runid-$x | cut -d"," -f7 | awk '{ sum += $1; n++ } END { if (n > 0) print "'$i' = " sum / n ; }' >> results/summary
   done
   echo "" >> "results/summary"
done

cp partition_sizes_original partition_sizes

bash close-all-terminals.sh
