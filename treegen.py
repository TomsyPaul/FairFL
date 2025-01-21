import networkx as nx 
import matplotlib.pyplot as plt


def largest_power_le(n):
    k=0
    while(n>=pow(2,k)):
       k+=1
    return pow(2,k-1)
     
def generate_tree(n,i):
  if(n<=3 and i==0):
    print("Error, n<3")
    return (0,[])
  else:
    if(n==4):
      return (i+3,[(i,i+1),(i+1,i+3),(i+2,i+3)])
#    elif(n==5):
#      return [(i,i+1),(i+1,i+3),(i+2,i+4),(i+4,i+3)]  
#    elif(n==6):
#      return [(i,i+1),(i+1,i+3),(i+2,i+4),(i+4,i+5),(i+5,i+3)]  
#    elif(n==7):
#      return [(i,i+1),(i+1,i+4),(i+4,i+6),(i+2,i+3),(i+3,i+5),(i+5,i+6)]  
    else:
      k=largest_power_le(n)
      if(k==n):
        r1,l1=generate_tree(n//2,i)
        r2,l2=generate_tree(n//2,i+n//2)
        return (n+i-1,l1+l2+[(n//2+i-1,i+n-1)])
      else:
        if(n-k<4):
           r,l=generate_tree(k,i)
           if(n-k == 1):
             l.remove((k+i-2,k+i-1))
             l+=[(k+i-2,k+i)]
             l+=[(k+i,k+i-1)]
           elif(n-k == 2):
             l.remove((k+i-2,k+i-1))
             l+=[(k+i-2,k+i)]
             l+=[(k+i,k+i+1)]
             l+=[(k+i+1,k+i-1)]
           else:
             l.remove((k+i-3,k+i-1))
             l.remove((k+i-2,k+i-1))
             l+=[(k+i-3,k+i)]
             l+=[(k+i,k+i-1)]
             
             l+=[(k+i-2,k+i+1)]
             l+=[(k+i+1,k+i+2)]
             l+=[(k+i+2,k+i-1)]
           return (r,l)
        else:
           r1,l1=generate_tree(k,i)   
           r2,l2=generate_tree(n-k,k+i)
           return r1,l1+l2+[(r2,r1)]  

          
if __name__ == "__main__":
     n=input("Enter n")
     r,t=generate_tree(int(n),0)
     print(r,t)
#     for edge in t:
#        print(edge[0],">",edge[1])
        

