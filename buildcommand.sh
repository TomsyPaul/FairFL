#! /bin/bash
if [ -z $1 ]
then 
image='9446917617/mydfl-image:pytorch-docker'
else
image=$1
fi
ssh -n tomsy@$1 docker build -t $image /home/tomsy/mydfl
