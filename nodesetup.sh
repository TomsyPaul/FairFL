#! /bin/bash
read username
sudo adduser $username
sudo apt update && sudo apt install -y docker.io
sudo usermod -aG docker,sudo $username
sudo docker swarm join --token SWMTKN-1-0m916vou4yqlo1ur45zu8yynl8pca9vn7cwv1m5g5uywdje53y-cds62w90rpn72z01rbhmkwpgr 172.16.89.5:2377
mkdir /home/$username/mydfl
sudo chown -R $username:$username /home/$username/mydfl
