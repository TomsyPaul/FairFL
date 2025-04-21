#! /bin/python3
import csv
import argparse

import numpy as np
'''Courtesy: https://www.datacamp.com/tutorial/k-means-clustering-python'''

parser = argparse.ArgumentParser()
parser.add_argument("--size", type=int)
parser.add_argument("--rounds", type=int)
args = parser.parse_args()
size = int(args.size)

with open('indicesfile', newline='') as csvfile1:
    partition_indices = list(csv.reader(csvfile1))
for i in range(len(partition_indices)):
    partition_indices[i]=partition_indices[i][:-1]#remove the empty value due to comma at the end
    partition_indices[i]=[int(partition_indices[i][j]) for j in range(len(partition_indices[i]))]#convert from string to int values

newpartysizes=[len(i) for i in partition_indices]
uniquesizes=list(set(newpartysizes))
uniquesizes.sort()
rounds=len(uniquesizes)
currentpartysizes=[uniquesizes[0] for _ in newpartysizes]

currentindex=0
for i in range(rounds):
   file2=open("indicesfile"+str(i),"w")
   for item in range(len(newpartysizes)):
     newlength=currentpartysizes[0]
     for x in range(newlength):
         file2.write(str(partition_indices[item][currentindex+x])+",")
     file2.write("\n")
   file2.close()
   currentindex+=newlength
   currentpartysizes=[newpartysizes[x] - currentpartysizes[x] for x in range(len(currentpartysizes))]
   temp_sizes=[]
   for item in currentpartysizes:
     if item > 0:
         temp_sizes += [item]
   newpartysizes = temp_sizes
   uniquesizes=list(set(newpartysizes))
   uniquesizes.sort()
   currentpartysizes=[uniquesizes[0] for _ in newpartysizes]

print(rounds)
