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

nextadjustment=None

def getnextadjustment(key):
    newstring=key
    while True:
        newstring=str(int(sha256(newstring.encode('utf-8')).hexdigest(),16))
        strlength=len(newstring)
        for i in range(strlength-4):
#           yield newstring[i:i+4]
#            yield '0.'+newstring[i:i+4]
            yield '0.'+newstring[i:i+4]
        newstring=newstring[strlength-4:strlength]
  
def set_leaf_pair_adder(rank, size, aux):
    with open('layout-up', newline='') as csvfile1:
        btreedata1 = list(csv.reader(csvfile1))
    edge_dest=[currentrow[1] for currentrow in btreedata1]
    if str(rank) not in edge_dest:
        aux["isleaf"]=True
        if rank % 4 == 0:           
           aux["adder"]=True
           aux["partner"] = rank + 2
        else:
           aux["adder"]=False   
           aux["partner"] = rank - 2        
    else:
        aux["isleaf"]=False    
            
def kld(p,q):
    return sum(p[i] * log2(p[i]/q[i]) for i in range(len(p)))



#https://stackoverflow.com/questions/1908878/netcat-implementation-in-python
def netcat(hostname, port, content):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect((hostname, port))
    s.sendall(content)
#    s.shutdown(socket.SHUT_WR)
#    s.close()

def run(rank, size, epochs, K, averager, runid, roundid):
    aux=dict(isleaf=False,partner=0,adder=False,key="1234567890")
    set_leaf_pair_adder(rank, size, aux)
    if aux["isleaf"] == True:
            with open('keys', newline='') as csvfile4:
                allkeys = list(csv.reader(csvfile4))
                aux["key"]=allkeys[rank//4][0]
            nextadjustment = getnextadjustment(aux["key"])

    local_counts=[]
    f1=open("local_counts","r")
    for i in f1.readlines():
       local_counts+=[int(i.strip())]
    f1.close()

    additive = 0.0
    if aux["isleaf"] == True:
                if aux["adder"] == True:
                    additive += float(next(nextadjustment))
                else:
                    additive -= float(next(nextadjustment))
    sending_copy = torch.Tensor([i+additive for i in local_counts])
    receiving_copy = sending_copy.clone()
    
    with open('layout-up', newline='') as csvfile1:
        btreedata1 = list(csv.reader(csvfile1))
    with open('layout-down', newline='') as csvfile2:
        btreedata2 = list(csv.reader(csvfile2))

#Tree Upward
    for currentrow in btreedata1:
                         if int(currentrow[0]) == rank:
                           dist.send(tensor=sending_copy,dst=int(currentrow[1]))
                           
                         elif int(currentrow[1]) == rank:
                           dist.recv(tensor=receiving_copy,src=int(currentrow[0]))
                           sending_copy=torch.Tensor([sending_copy[i]+receiving_copy[i] for i in range(len(sending_copy))])

#Tree Downward
    for currentrow in btreedata2:
                        if int(currentrow[0]) == rank:
                           dist.send(tensor=sending_copy,dst=int(currentrow[1]))
                        elif int(currentrow[1]) == rank:
                           dist.recv(tensor=receiving_copy,src=int(currentrow[0]))
                           sending_copy=receiving_copy
#           dist.all_reduce(param.grad.data, op=dist.reduce_op.SUM, group=0)
    global_counts=[int(sending_copy[i]) for i in range(len(sending_copy))]
    p=[float(global_counts[i])/sum(global_counts) for i in range(10)]
    q=[float(local_counts[i])/sum(local_counts) for i in range(10)]
    
    
    coordinator="172.16.64.126"
    netcat(coordinator,23632,f"{rank},{kld(p,q)}\n".encode("utf-8"))

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
