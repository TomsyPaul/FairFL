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

#set files to upload
>files-to-upload
#echo keys >> files-to-upload
echo run.py >> files-to-upload
#echo partition_sizes >> files-to-upload

>partition_sizes
for((i=0;i<$size;i++))
do
# common=`echo 1.0/$size | bc -l`
 common=`echo 1.0/16 | bc -l`
 echo -n "$common, ">>partition_sizes 
done   

cumulative_size=0

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

cp hostips hostips_backup
cp partition_sizes partition_sizes_original
python3 generate_partitions.py --size=$size

rounds=`cat partition_sizes |tr -d " " |  tr "," "\n" | head -n $size | sort -n | uniq|wc -l`
epochs=`echo $epochs/$rounds | bc`

for((x=0;x<rounds;x++))
do

   cp tempfile$x partition_sizes
   
   >files-to-upload
   echo partition_sizes >> files-to-upload
   
   currentworldsize=`grep -o "," tempfile$x | wc -l`
   head -n $currentworldsize hostips_backup > hostips
   
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
        gnome-terminal --window -- bash -c "ssh -n tomsy@$ip docker exec c$i python run.py --rank=$i --size=$currentworldsize --epochs=$epochs --averager=$averager --K=$currentworldsize --runid=$runid --round=$x; echo Output of $i; exec bash"   
        ((i++))     	
    fi
   done < hostips

   echo "Completed Round $x"
   echo "Cumulative Size = $cumulative_size"
   
   #read
   #for((i=0;i<$currentworldsize;i++))
   #do
   #nc -l 1234 
   #done
   while [[ `cat nc_output.txt | wc -l` < $cumulative_size ]]
   do
      sleep 1
      echo "nc_output count = `cat nc_output.txt | wc -l`"
   done
   
   
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
cp hostips_backup hostips
bash close-all-terminals.sh

