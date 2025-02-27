#! /bin/python3
import csv
import argparse

from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score
import numpy as np
'''Courtesy: https://www.datacamp.com/tutorial/k-means-clustering-python'''

parser = argparse.ArgumentParser()
parser.add_argument("--size", type=int)
parser.add_argument("--rounds", type=int)
args = parser.parse_args()
size = int(args.size)

mylist=[]
fits = []
score = []

f=open("testout","r")
for i in f.readlines():
    mylist+=[float(i.strip())]
arr = np.array(mylist, dtype='float32').reshape(-1,1)
for k in range(2,size):
   model = KMeans(n_clusters = k, random_state = 0, n_init='auto')
   model.fit(arr) 
   fits.append(model)
   score.append(silhouette_score(arr, model.labels_, metric='euclidean'))
for k in range(2,size-1):
#   print(str(k)+str(fits[k-2].labels_))   
#   print(score[k-2])
   if score[k-2] < score[k-1]:
      best=score[k-2]
      best_partition=fits[k-2].labels_
      break
l=list(best_partition)
classorder=[(i,l.index(i)) for i in range(k)]
classorder.sort(key=lambda s:s[1])
classsizes=[l.count(i) for i in (classorder[j][0] for j in range(k))]

rounds=len(classsizes)

for i in range(rounds):
   file1=open("tempfile"+str(i),"w")
   for item in range(sum(classsizes)):
     file1.write(str(float(1)/(size*rounds))+",")
   file1.close()
   classsizes.pop()
print(rounds)

