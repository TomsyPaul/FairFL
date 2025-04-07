#! /bin/bash
read -p "Enter Worldsize " worldsize

#set hostips
head -n $worldsize hostipsall > hostips

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
