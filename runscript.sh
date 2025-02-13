#! /bin/bash
#for i in `wc -l hostips`
size=`wc -l hostips | cut -d" " -f1`
coding=$1
epochs=$2
averager=$3
K=$4
runid=$5


#set files to upload
>files-to-upload
#echo keys >> files-to-upload
echo run.py >> files-to-upload
#echo partition_sizes >> files-to-upload


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

cp partition_sizes partition_sizes_original

currentworldsize=$worldsize

rounds=`cat partition_sizes |tr -d " " |  tr "," "\n" | head -n $worldsize | sort -n | uniq|wc -l`

unique_array=()
for((i=0;i<rounds;i++))
do 
unique_array+=(`cat partition_sizes |tr -d " " |  tr "," "\n" | head -n $worldsize | sort -n | uniq | head -n $((i+1)) | tail -n 1`)
done


for((i=0;i<$rounds;i++))
do

cp partition_sizes partition_sizes_temp

partition_temp_array=(`cat partition_sizes_temp|tr -d ","`)
partition_sizes_array=()
for t in ${!partition_temp_array[@]}
do 
partition_sizes_array+=(`echo ${partition_temp_array[$t]}-${unique_array[0]} | bc -l`)
done



newsize=0
for((i=0;i<currentworldsize;i++))
do

done

>files-to-upload
echo layout-up >> files-to-upload
echo layout-down >> files-to-upload
#echo secrets >> files-to-upload
echo keys >> files-to-upload
#echo run.py >> files-to-upload
echo partition_sizes >> files-to-upload

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
   gnome-terminal --window -- bash -c "ssh -n tomsy@$ip docker exec c$i python run.py --rank=$i --size=$size --epochs=$epochs --averager=$averager --K=$K --runid=$runid; echo Output of $i; exec bash"   
 ((i++))     	
 fi
done < hostips




done





