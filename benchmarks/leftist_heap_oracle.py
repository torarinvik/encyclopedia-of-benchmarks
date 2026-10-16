from collections.abc import Sequence
MAX_INPUT_LENGTH=43
INVALID_RESULT=-1.0e300
class Node:
 def __init__(self,key): self.key=key; self.left=-1; self.right=-1; self.npl=0
def merge(nodes,a,b):
 if a<0:return b
 if b<0:return a
 if nodes[a].key>nodes[b].key:a,b=b,a
 nodes[a].right=merge(nodes,nodes[a].right,b)
 if nodes[a].left<0: nodes[a].left=nodes[a].right; nodes[a].right=-1
 else:
  if nodes[nodes[a].left].npl<nodes[nodes[a].right].npl:nodes[a].left,nodes[a].right=nodes[a].right,nodes[a].left
  nodes[a].npl=nodes[nodes[a].right].npl+1
 return a
def expected_result(values:Sequence[int])->float:
 if not isinstance(values,(list,tuple)) or not 1<=len(values)<=MAX_INPUT_LENGTH:return INVALID_RESULT
 if any(type(x)is not int or not -(1<<63)<=x<(1<<63) for x in values):return INVALID_RESULT
 n=values[0]
 if not 0<=n<=14 or len(values)!=1+3*n:return INVALID_RESULT
 nodes=[]; roots=[-1,-1]; result=0; extracts=0
 for i in range(n):
  kind,h,val=values[1+3*i:4+3*i]
  if kind not in (0,1,2,3):return INVALID_RESULT
  if kind in (0,1,3) and h not in (0,1):return INVALID_RESULT
  if kind==0:
   if not 0<=val<=9:return INVALID_RESULT
   nodes.append(Node(val)); roots[h]=merge(nodes,len(nodes)-1,roots[h])
  elif kind==1:
   if val!=0:return INVALID_RESULT
   extracts+=1
   if extracts>10:return INVALID_RESULT
   r=roots[h]; got=-1
   if r>=0:got=nodes[r].key; roots[h]=merge(nodes,nodes[r].left,nodes[r].right)
   result=result*13+got+2
  elif kind==2:
   if h!=0 or val!=0:return INVALID_RESULT
   roots[0]=merge(nodes,roots[0],roots[1]); roots[1]=-1
  else:
   if val!=0:return INVALID_RESULT
   roots[h]=-1
 return float(result)
