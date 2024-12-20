#! /bin/bash
#if [ ! -z $1 ] 
#then
#command=$1
#else 
#command=""
#fi
for i in `cat hostips`
do scp -r /home/tomsy/mydfl tomsy@$i: 
done
