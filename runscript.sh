#! /bin/bash
#for i in `wc -l hostips`
size=`wc -l hostips | cut -d" " -f1`
coding=$1
epochs=$2
averager=$3
K=$4
runid=$5

cp indicesfile indicesfile_original

>nc_output.txt
nc -k -u -l 23432  >> nc_output.txt&

>nc_local_counts.txt
nc -k -u -l 23532  >> nc_local_counts.txt&

>nc_result.txt
nc -k -u -l 23632  >> nc_result.txt&

#set files to upload
>files-to-upload
echo run.py >> files-to-upload
echo indicesfile >> files-to-upload


tar -cvzf files-to-upload.gz -T files-to-upload
#echo keys >> files-to-upload
#echo partition_sizes >> files-to-upload

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


cumulative_size=0

rounds=`python3 generate_partitions.py --size=$size`
epochs=`echo $epochs/$rounds | bc`

for((x=0;x<rounds;x++))
do

   cp indicesfile$x indicesfile
   
   >files-to-upload
   echo indicesfile >> files-to-upload
   
   currentworldsize=`cat indicesfile$x | wc -l`
   head -n $currentworldsize hostips > selected_hosts
   
   cumulative_size=$((cumulative_size+currentworldsize))
   
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
   done < selected_hosts
   
   i=0
   while  read ip
   do
     if [ ! -z $ip ]
     then
        gnome-terminal --window -- bash -c "ssh -n tomsy@$ip docker exec c$i python run.py --rank=$i --size=$currentworldsize --epochs=$epochs --averager=$averager --K=$K --runid=$runid --roundid=$x --masteraddr=n0 --masterport=12${x}21; echo Output of $i; exec bash"   
        ((i++))     	
    fi
   done < selected_hosts
   
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

cp indicesfile_original indicesfile

bash close-all-terminals.sh
