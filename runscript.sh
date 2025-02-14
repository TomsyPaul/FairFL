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
python3 generate_partitions.py --size=$size

rounds=`cat partition_sizes |tr -d " " |  tr "," "\n" | head -n $worldsize | sort -n | uniq|wc -l`
epochs=`echo $epochs/$rounds | bc`

for((x=0;x<rounds;x++))
do

cp tempfile$x partition_sizes

>files-to-upload
echo layout-up >> files-to-upload
echo layout-down >> files-to-upload
#echo secrets >> files-to-upload
echo keys >> files-to-upload
#echo run.py >> files-to-upload
echo partition_sizes >> files-to-upload

currentworldsize=`grep -o "," tempfile$x | wc -l`

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
   gnome-terminal --window -- bash -c "ssh -n tomsy@$ip docker exec c$i python run.py --rank=$i --size=$currentworldsize --epochs=$epochs --averager=$averager --K=$K --runid=$runid; echo Output of $i; exec bash"   
 ((i++))     	
 fi
done < hostips




done

cp partition_sizes_original partition_sizes 
rm tempfile*


