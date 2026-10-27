"""Independent Edmonds-Karp verifier oracle for the leftmost-flow profile."""
from __future__ import annotations
import struct
from collections.abc import Sequence
MAX_INPUT_LENGTH=60
MAX_OUTPUT_BYTES=8
MAX_N=6
MAX_M=10

def _decode(a):
    if not 4<=len(a)<=MAX_INPUT_LENGTH or any(type(x)is not int or not -(1<<63)<=x<(1<<63) for x in a):return None
    n,m,s,t=a[:4]
    if not 2<=n<=MAX_N or not 1<=m<=MAX_M or not 0<=s<n or not 0<=t<n or s==t:return None
    pos=4
    if len(a)<4+3*m:return None
    edges=[];seen_pairs=set()
    for _ in range(m):
        u,v,c=a[pos:pos+3];pos+=3;pair=(min(u,v),max(u,v))
        if not 0<=u<n or not 0<=v<n or u==v or not 0<=c<=5 or pair in seen_pairs:return None
        seen_pairs.add(pair);edges.append((u,v,c))
    rotations=[];counts=[[0,0] for _ in edges]
    for v in range(n):
        if pos>=len(a):return None
        degree=a[pos];pos+=1
        if not 0<=degree<n or pos+degree>len(a):return None
        row=a[pos:pos+degree];pos+=degree
        if len(set(row))!=degree:return None
        for e in row:
            if not 0<=e<m:return None
            u,w,_=edges[e]
            if v==u:counts[e][0]+=1
            elif v==w:counts[e][1]+=1
            else:return None
        rotations.append(row)
    if pos!=len(a) or any(c!=[1,1] for c in counts):return None
    reachable={s};todo=[s]
    while todo:
        x=todo.pop()
        for u,v,_ in edges:
            y=v if x==u else u if x==v else -1
            if y>=0 and y not in reachable:reachable.add(y);todo.append(y)
    if len(reachable)!=n:return None
    return n,m,s,t,edges

def expected_output(values:Sequence[int]|None,capacity:int|None=None,output_is_null:bool=False,input_is_null:bool=False,input_length:int|None=None)->tuple[int,bytes]:
    if type(output_is_null)is not bool or type(input_is_null)is not bool:return -1,b""
    if capacity is not None and (type(capacity)is not int or capacity<0):return -1,b""
    if input_length is not None and (type(input_length)is not int or not 0<=input_length<=MAX_INPUT_LENGTH):return -1,b""
    if input_is_null or not isinstance(values,(list,tuple)):return -1,b""
    if input_length is not None and len(values)!=input_length:return -1,b""
    d=_decode(values)
    if d is None:return -1,b""
    n,m,s,t,edges=d
    residual=[[0]*n for _ in range(n)]
    for u,v,c in edges:residual[u][v]+=c
    total=0
    while True:
        parent=[-1]*n;parent[s]=s;queue=[s]
        for u in queue:
            for v in range(n):
                if parent[v]<0 and residual[u][v]>0:parent[v]=u;queue.append(v)
        if parent[t]<0:break
        delta=10**9;v=t
        while v!=s:delta=min(delta,residual[parent[v]][v]);v=parent[v]
        v=t
        while v!=s:u=parent[v];residual[u][v]-=delta;residual[v][u]+=delta;v=u
        total+=delta
    payload=struct.pack('<q',total)
    if output_is_null or capacity is not None and capacity<len(payload):return -2,b""
    return len(payload),payload
