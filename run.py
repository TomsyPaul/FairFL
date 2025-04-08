"""run.py: adapted from https://pytorch.org/tutorials/intermediate/dist_tuto.html"""
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


class Net(nn.Module):
    """ Network architecture. """
    def __init__(self):
        super(Net, self).__init__()
        self.conv1 = nn.Conv2d(1, 10, kernel_size=5)
        self.conv2 = nn.Conv2d(10, 20, kernel_size=5)
        self.conv2_drop = nn.Dropout2d()
        self.fc1 = nn.Linear(320, 50)
        self.fc2 = nn.Linear(50, 10)
        self.mybuf=[]
        self.splitbuf=[]
#        self.secret=float(0)
        self.aux=dict(isleaf=False,partner=0,adder=False,key="1234567890")
    def forward(self, x):
        x = F.relu(F.max_pool2d(self.conv1(x), 2))
        x = F.relu(F.max_pool2d(self.conv2_drop(self.conv2(x)), 2))
        x = x.view(-1, 320)
        x = F.relu(self.fc1(x))
        x = F.dropout(x, training=self.training)
        x = self.fc2(x)
        return F.log_softmax(x, dim=1)


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

def basic_average_gradients(model):
    """ Gradient averaging using allreduce."""
#    print("Using DFL")
    size = dist.get_world_size()
    rank = dist.get_rank()
    for param in model.parameters():
            dist.all_reduce(param.grad.data, op=dist.reduce_op.SUM)
            param.grad.data /= size


#https://stackoverflow.com/questions/1908878/netcat-implementation-in-python
def netcat(hostname, port, content):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect((hostname, port))
    s.sendall(content)
#    s.shutdown(socket.SHUT_WR)
#    s.close()

cumulativeoverhead=0.0
#def run(rank, size):
#   """ Distributed function to be implemented later. """
#   print("Rank = ", rank)
def run(rank, size, epochs, K, averager, runid, roundid):
    """ Distributed Synchronous SGD Example """
    torch.manual_seed(1234)
    train_set, bsz = partition_dataset()
    model = Net()
#    model = model
#    model = model.cuda(rank)

    if roundid != 0:
       model.load_state_dict(torch.load(runid+"round-"+str(roundid-1), weights_only=True))

    optimizer = optim.SGD(model.parameters(), lr=0.01, momentum=0.5)

    num_batches = ceil(len(train_set.dataset) / float(bsz))

    LOG_FILE = "/logs/"+str(size)+"-"+averager+"-"+str(epochs)+"-"+str(runid)+"-"+str(roundid)
    logging.basicConfig(filename=LOG_FILE, format='%(asctime)s %(message)s', level=logging.INFO, datefmt='%Y-%m-%d_%H-%M-%S')
    starttime = time.time()
    
    global cumulativeoverhead
    
    for epoch in range(epochs):
        epoch_loss = 0.0
        skip=0
        for data, target in train_set:
            data, target = Variable(data), Variable(target)
#            data, target = Variable(data.cuda(rank)), Variable(target.cuda(rank))
            optimizer.zero_grad()
            output = model(data)
            loss = F.nll_loss(output, target)
            epoch_loss += loss
            loss.backward()
            skip += 1
            if (skip % K) == 0:
               if averager == "DFLBASIC":
                  basic_average_gradients(model)
            optimizer.step()
        print('Rank ',
            dist.get_rank(), ', epoch ', epoch, ': ',
            epoch_loss / num_batches)
        logging.info(f"Rank,{rank},round,{roundid},epoch,{epoch},{epoch_loss/num_batches:.4f}")
    endtime = time.time()
    print(endtime - starttime)
    logging.info(f"Rank,{rank},round,{roundid},TIME,{endtime-starttime:.4f}")
    torch.save(model.state_dict(), runid+"round-"+str(roundid))   
    latesttime = time.time()
    coordinator="172.16.64.126"
    netcat(coordinator,23432,f"{rank}\n".encode("utf-8"))

def init_processes(rank, size, epochs, K, averager, runid, fn, roundid, backend='gloo'):
   """ Initialize the distributed environment. """
   dist.init_process_group(backend, rank=rank, world_size=size)
   fn(rank, size, epochs, K, averager, runid, roundid)

if __name__ == "__main__":
#    rank=int(os.environ['LOCAL_RANK'])
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
    parser.add_argument("--masteraddr", type=str)
    parser.add_argument("--masterport", type=str)
    args = parser.parse_args()
    rank = int(args.rank)
    size = int(args.size)
    epochs = int(args.epochs)
    averager = args.averager
    K = int(args.K)
    runid = args.runid
    roundid = int(args.roundid)
    masteraddr = args.masteraddr
    masterport = args.masterport
    
    os.environ['GLOO_SOCKET_IFNAME']="eth0"
    os.environ['MASTER_ADDR'] = masteraddr
    os.environ['MASTER_PORT'] = masterport    

    init_processes(rank, size, epochs, K, averager, runid, run, roundid)
