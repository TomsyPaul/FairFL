#! /bin/bash
for((i=0;i<3;i++))
do
gnome-terminal -e bash -c "ls ; exec bash"
done
