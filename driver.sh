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
   bash copytoall.sh layout
   bash copytoall.sh keys
   bash copytoall.sh secrets
   bash buildall.sh
   read
   bash setup.sh $5
   bash applytoall.sh 'docker start' c
else
echo $averager-$epochs-$runid>>logslist
bash runscript.sh $coding $epochs $averager $K $runid
read
echo "$2,$3,$K,$runid" > "results/$averager-$epochs-$runid"
echo -e "******************\n" >> "results/$averager-$epochs-$runid"
bash applytoallcontainers.sh "cat /logs/$averager-$epochs-$runid;echo" >> "results/$averager-$epochs-$runid"
echo -e "Result..\n"
cat results/$averager-$epochs-$runid
echo "$2,$3,$K,$runid" >> "results/summary"
grep TIME results/$averager-$epochs-$runid | cut -d"," -f4 | awk '{ sum += $1; n++ } END { if (n > 0) print "Average time taken = " sum / n "\n"; }' >> results/summary

echo -e "Average Loss\n" >> "results/summary"

for((i=0;i<$epochs;i++))
do 
grep "epoch,$i" results/$averager-$epochs-$runid | cut -d"," -f5 | awk '{ sum += $1; n++ } END { if (n > 0) print "'$i' = " sum / n ; }' >> results/summary
done
echo "" >> "results/summary"
bash close-all-terminals.sh
fi
