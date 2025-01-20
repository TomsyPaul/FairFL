def generate_tree(n,i):
  if(int(n)&int((n-1))==0):  
    if(n >= 8):
        l1=generate_tree(n//2,i)
        l2=generate_tree(n//2,i+n//2)
        return l1+l2+[(n//2+i-1,i+n-1)]
    else:
        if(n==4):
            return [(i,i+1),(i+1,i+3),(i+2,i+3)]
        else:
            print("Error, n<4")
            return []
                    
        
