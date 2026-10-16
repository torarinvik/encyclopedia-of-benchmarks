"""Oracle for bounded Kahn DAG processing count."""
from collections.abc import Sequence
MAX_VERTICES=32
MAX_EDGES=128
MAX_INPUT_LENGTH=2+2*MAX_EDGES
INVALID_RESULT=-2
CYCLE_RESULT=-1
I64_MIN,I64_MAX=-(1<<63),(1<<63)-1
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or not 2<=len(values)<=MAX_INPUT_LENGTH or any(type(x)is not int or not I64_MIN<=x<=I64_MAX for x in values):return INVALID_RESULT
    n,e=values[:2]
    if not 0<=n<=MAX_VERTICES or not 0<=e<=MAX_EDGES or len(values)!=2+2*e:return INVALID_RESULT
    adj=[[False]*n for _ in range(n)];ind=[0]*n
    for i in range(e):
        a,b=values[2+2*i:4+2*i]
        if not 0<=a<n or not 0<=b<n:return INVALID_RESULT
        if not adj[a][b]:adj[a][b]=True;ind[b]+=1
    queue=[i for i in range(n) if ind[i]==0];head=processed=0
    while head<len(queue):
        v=queue[head];head+=1;processed+=1
        for w in range(n):
            if adj[v][w]:
                ind[w]-=1
                if ind[w]==0:queue.append(w)
    return processed if processed==n else CYCLE_RESULT
