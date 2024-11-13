#! /bin/bash
#cd ~/mydfl
#git pull https://tomsypaul@github.com/TomsyPaul/mydfl.git 
sudo docker build -t 9446917617/mydfl-image:$1 .
sudo docker create -it --net test-net --hostname n$2 --name c$2  9446917617/mydfl-image:$1
sudo docker start -i -a c$2
