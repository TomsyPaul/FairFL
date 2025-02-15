#! /bin/bash
#cd ~/mydfl
#git pull https://tomsypaul@github.com/TomsyPaul/mydfl.git 
read -p "Enter Worldsize " worldsize

#set hostips
head -n $worldsize hostipsall > hostips

##generate secrets (n-1)
#>secrets
#secretsum=0
#for((i=1;i<$worldsize;i++))
#do
#thisrandom=`echo $RANDOM/100000 | bc -l|cut -c 1-8`
#echo "$thisrandom" >> secrets
#secretsum=`echo $secretsum+$thisrandom | bc -l|cut -c 1-8`
#done
##generate secrets (n-th)
#echo "-$secretsum" >> secrets


#generate partition_sizes
#>partition_sizes
#for((i=0;i<$worldsize;i++))
#do
#common=`echo 1.0/$worldsize | bc -l`
#echo -n "$common, ">>partition_sizes 
#done


#rest of the process
mkdir -p results
coding=$1
epochs=$2
averager=$3
K=$4
runid=`date +'%Y-%m-%d_%H-%M-%S'`
if [ $coding == 'N' ]
then
   bash applytoall.sh 'docker stop' c
   bash applytoall.sh 'docker rm' c
   
#  bash applytoall.sh 'docker image rm 9446917617/mydfl-image:pytorch-docker'
   bash copytoall.sh Dockerfile
   bash copytoall.sh run.py
   bash copytoall.sh layout-up
   bash copytoall.sh layout-down
   bash copytoall.sh layout
   bash copytoall.sh keys
   bash copytoall.sh secrets
   bash buildall.sh
   read
   bash setup.sh $5
   bash applytoall.sh 'docker start' c
else
echo $worldsize-$averager-$epochs-$runid>>logslist
bash runscript.sh $coding $epochs $averager $K $runid
read
fi
