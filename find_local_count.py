"""find_local_count.py: Finds the count of each digit in the node and stores in local_counts file. Then the rank is send to the coordinator. The coordinator on receiving the ranks of all nodes, call kld.py on each node."""
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

class Partition(object):
    """ Dataset-like object, but only access a subset of it. """

    def __init__(self, data, index):
        self.data = data
        self.index = index

    def __len__(self):
        return len(self.index)

    def __getitem__(self, index):
        data_idx = self.index[index]
        return self.data[data_idx]


class DataPartitioner(object):
    """ Partitions a dataset into different chuncks. """

    def __init__(self, data, indices=[[0,1,2],[3,4,5,6],[7,8,9]], seed=1234):
        self.data = data
        self.partitions = []
#        rng = Random()
#        rng.seed(seed)
#        data_len = len(data)
#        indexes = [x for x in range(0, data_len)]
#        rng.shuffle(indexes)

        for i in indices:
#            part_len = len(i)
#            self.partitions.append(indexes[0:part_len])
             self.partitions.append(i)
#            indexes = indexes[part_len:]

    def use(self, partition):
        return Partition(self.data, self.partitions[partition])

def partition_dataset():
    """ Partitioning MNIST """
    dataset = datasets.MNIST(
        './data',
        train=True,
        download=True,
        transform=transforms.Compose([
            transforms.ToTensor(),
            transforms.Normalize((0.1307, ), (0.3081, ))
        ]))
    size = dist.get_world_size()
    bsz = 128 // size
#    partition_sizes = [1.0 / size for _ in range(size)]
    with open('indicesfile', newline='') as csvfile1:
        partition_indices = list(csv.reader(csvfile1))
    for i in range(len(partition_indices)):
        partition_indices[i]=partition_indices[i][:-1]
        partition_indices[i]=[int(partition_indices[i][j]) for j in range(len(partition_indices[i]))]
    partition = DataPartitioner(dataset, partition_indices)
    partition = partition.use(dist.get_rank())
    train_set = torch.utils.data.DataLoader(
        partition, batch_size=bsz, shuffle=False)
    return train_set, bsz

#https://stackoverflow.com/questions/1908878/netcat-implementation-in-python
def netcat(hostname, port, content):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect((hostname, port))
    s.sendall(content)
#    s.shutdown(socket.SHUT_WR)
#    s.close()

def run(rank, size, epochs, K, averager, runid, roundid):
    """ Distributed Synchronous SGD Example """
    torch.manual_seed(1234)
    train_set, bsz = partition_dataset()
    local_counts=[[train_set.dataset[i][1] for i in range(len(train_set.dataset))].count(j) for j in range(10)]
    f1=open("local_counts","w")
    for i in local_counts:
       f1.write(str(i)+"\n")
    f1.close()
    
    coordinator="172.16.64.126"
    netcat(coordinator,23532,f"{rank},{sum(local_counts)}\n".encode("utf-8"))

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
