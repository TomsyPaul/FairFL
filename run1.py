"""run.py:"""
#!/usr/bin/env python
import os
import torch
import torch.distributed as dist
from torch.multiprocessing import Process
import argparse


def run(rank, size):
   """ Distributed function to be implemented later. """
   print("Rank =    ", rank)

def init_processes(rank, size, fn, backend='gloo'):
   """ Initialize the distributed environment. """
   dist.init_process_group(backend, rank=rank, world_size=size)
   fn(rank, size)

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
    args = parser.parse_args()
    rank = int(args.rank)
    size = int(args.size)

    init_processes(rank, size, run)
    print("Message - all processes crossed barrier - from Rank ",rank)

