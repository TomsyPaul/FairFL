"""kld.py: adapted from https://pytorch.org/tutorials/intermediate/dist_tuto.html, finds the KL Divergence of the node from local_counts file and global_counts which is generated through aggregation."""
#!/usr/bin/env python
import os
import torch
import torch.distributed as dist
from torch.multiprocessing import Process
import argparse
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
import numpy as np
import math
import csv
import copy
import logging
import time
from hashlib import sha256

from math import ceil
from random import Random
from torch.autograd import Variable
from torchvision import datasets, transforms
import torchvision.models as models

import socket
from math import log2

          
def euclidean(p,q):
    return sum((p[i]-q[i])**2 for i in range(len(p)))/2



#https://stackoverflow.com/questions/1908878/netcat-implementation-in-python
def netcat(hostname, port, content):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect((hostname, port))
    s.sendall(content)
#    s.shutdown(socket.SHUT_WR)
#    s.close()

def run(rank, size, epochs, K, averager, runid, roundid):

    local_counts=[]
    f1=open("local_counts","r")
    for i in f1.readlines():
       local_counts+=[int(i.strip())]
    f1.close()

    local_copy = torch.Tensor([i for i in local_counts])
    global_copy = local_copy.clone()
    
    dist.all_reduce(global_copy, op=dist.reduce_op.SUM)
    
    global_counts=[int(global_copy[i]) for i in range(len(global_copy))]
    p=[float(global_counts[i])/sum(global_counts) for i in range(10)]
    q=[float(local_counts[i])/sum(local_counts) for i in range(10)]
#    N=sum(global_counts)
    n=sum(local_counts)
#    X=(1/N)*sum([global_counts[i]*log2(global_counts[i]/local_counts[i]) for i in range(len(global_counts))])
#    kld_plus_sum=X+log2((n/N)**((n-1)/n))
    coordinator="172.16.64.126"
#    netcat(coordinator,23632,f"{rank},{kld(p,q)+log2(sum(global_counts)/sum(local_counts))}\n".encode("utf-8"))
    netcat(coordinator,23632,f"{rank},{euclidean(p,q)/(n*n)}\n".encode("utf-8"))

def init_processes(rank, size, epochs, K, averager, runid, fn, roundid, backend='gloo'):
   """ Initialize the distributed environment. """
   dist.init_process_group(backend, rank=rank, world_size=size)
   fn(rank, size, epochs, K, averager, runid, roundid)

if __name__ == "__main__":
#    rank=int(os.environ['LOCAL_RANK'])
    os.environ['GLOO_SOCKET_IFNAME']="eth0"
    os.environ['MASTER_ADDR'] = 'n0'
    os.environ['MASTER_PORT'] = '12321'    
#    rank=1
#    size=3
    parser = argparse.ArgumentParser()
    parser.add_argument("--rank", type=int)
    parser.add_argument("--size", type=int)
    parser.add_argument("--epochs", type=int)
    parser.add_argument("--averager", type=str)
    parser.add_argument("--K", type=int)
    parser.add_argument("--runid", type=str)
    parser.add_argument("--roundid", type=int)
    args = parser.parse_args()
    rank = int(args.rank)
    size = int(args.size)
    epochs = int(args.epochs)
    averager = args.averager
    K = int(args.K)
    runid = args.runid
    roundid = int(args.roundid)
    init_processes(rank, size, epochs, K, averager, runid, run, roundid)
