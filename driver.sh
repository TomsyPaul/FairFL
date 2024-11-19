#! /bin/bash
#cd ~/mydfl
#git pull https://tomsypaul@github.com/TomsyPaul/mydfl.git 
bash applytoall.sh 'docker stop'
bash applytoall.sh 'docker rm'
bash setup.sh $1
bash master.sh


