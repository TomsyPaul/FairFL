#! /bin/bash
#cd ~/mydfl
#git pull https://tomsypaul@github.com/TomsyPaul/mydfl.git 
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
   bash buildall.sh
   read
   bash setup.sh $5
   bash applytoall.sh 'docker start' c
fi
echo $runid>>logslist
bash runscript.sh $coding $epochs $averager $K $runid
read
echo "$2,$3,$K,$runid" > "results/$runid"
echo -e "******************\n" >> "results/$runid"
bash applytoallcontainers.sh "cat /logs/$runid;echo" >> "results/$runid"
echo -e "Result..\n"
cat results/$runid
echo "$2,$3,$K,$runid" >> "results/summary"
grep TIME results/$runid | cut -d"," -f4 | awk '{ sum += $1; n++ } END { if (n > 0) print "Average time taken = " sum / n "\n"; }' >> results/summary


bash close-all-terminals.sh
