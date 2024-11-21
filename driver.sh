#! /bin/bash
#cd ~/mydfl
#git pull https://tomsypaul@github.com/TomsyPaul/mydfl.git 
bash applytoall.sh 'docker stop' c
bash applytoall.sh 'docker rm' c



#bash applytoall.sh 'docker image rm 9446917617/mydfl-image:pytorch-docker'

bash copytoall.sh Dockerfile
bash copytoall.sh run.py
bash copytoall.sh run1.py

bash buildall.sh
read

bash setup.sh $1
bash applytoall.sh 'docker start' c
bash runscript.sh


