"""run.py:"""
#!/usr/bin/env python
import os
import torch
import torch.distributed as dist
from torch.multiprocessing import Process
import argparse


def run(rank, size):
   """ Distributed function to be implemented later. """
   print("Rank = ", rank)
#   pass
def init_processes(rank, size, fn, backend='gloo'):
   """ Initialize the distributed environment. """
   os.environ['MASTER ADDR'] = '172.16.89.5'
   os.environ['MASTER PORT'] = '12321'
   dist.init_process_group(backend, rank=rank, world_size=size)
   fn(rank, size)
if __name__ == "__main__":
   size = 2

#   parser = argparse.ArgumentParser(description='For passing rank')
#   parser.add_argument('--rank', metavar='number', required=True,
#                        help='the rank of the process')
#   args = parser.parse_args()
   rank=1


#   processes = []
#   for rank in range(size):
   p = Process(target=init_processes, args=(rank, size, run))
   p.start()
#   processes.append(p)
#   for p in processes:
#       p.join()
   torch.distributed.barrier()
   print("Message - all processes crossed barrier - from Rank ",rank)


