#! /bin/python3
import csv
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--size", type=int)
parser.add_argument("--rounds", type=int)
args = parser.parse_args()
size = int(args.size)
rounds = int(args.rounds)

with open('partition_sizes_original', newline='') as csvfile1:
   original_sizes=list(csv.reader(csvfile1))
original_sizes=[float(original_sizes[0][i]) for i in range(size)]

round_sizes=[unique_sizes[0] for _ in original_sizes]

for i in range(rounds):


   file1=open("tempfile"+str(i),"w")
   for item in round_sizes:
     file1.write(str(item)+",")
   file1.close()

   
   

   round_sizes=[original_sizes[x] - round_sizes[x] for x in range(len(round_sizes))]
#   breakpoint()
   temp_sizes=[]
   for item in round_sizes:
     if item > 0.00001:
         temp_sizes += [item]
              
#   round_sizes.remove(float(0))
   original_sizes = temp_sizes
   
   unique_sizes=list(set(original_sizes))
   unique_sizes.sort()

   round_sizes=[unique_sizes[0] for _ in original_sizes]
   
   
