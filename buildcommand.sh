#! /bin/bash
ssh -n tomsy@$1 docker build -t 9446917617/mydfl-image:pytorch-docker /home/tomsy/mydfl
