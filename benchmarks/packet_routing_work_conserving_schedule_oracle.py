"""Independent per-link scan oracle for work-conserving packet routing."""
from __future__ import annotations
import struct
from collections.abc import Sequence
MAX_INPUT_LENGTH=99
MAX_OUTPUT_BYTES=1360
MAX_N=8
MAX_M=12
MAX_P=8
MAX_HOPS=MAX_P*(MAX_N-1)

def _parse(a):
    if not 3<=len(a)<=MAX_INPUT_LENGTH or any(type(x)is not int or not -(1<<63)<=x<(1<<63) for x in a):return None
    n,m,p=a[:3]
    if not 2<=n<=MAX_N or not 1<=m<=MAX_M or not 1<=p<=MAX_P:return None
    pos=3
    if pos+2*m>len(a):return None
    links=[];pairs=set()
    for _ in range(m):
        u,v=a[pos:pos+2];pos+=2;pair=(min(u,v),max(u,v))
        if not 0<=u<n or not 0<=v<n or u==v or pair in pairs:return None
        pairs.add(pair);links.append((u,v))
    routes=[]
    for _ in range(p):
        if pos+2>len(a):return None
        at=a[pos];k=a[pos+1];pos+=2
        if not 0<=at<n or not 1<=k<=n-1 or pos+k>len(a):return None
        route=list(a[pos:pos+k]);pos+=k
        if any(not 0<=e<m for e in route) or len(set(route))!=k:return None
        visited={at};x=at
        for e in route:
            u,v=links[e]
            if x==u:x=v
            elif x==v:x=u
            else:return None
            if x in visited:return None
            visited.add(x)
        routes.append((at,route))
    if pos!=len(a):return None
    return n,m,p,links,routes

def expected_output(values:Sequence[int]|None,capacity:int|None=None,output_is_null:bool=False,input_is_null:bool=False,input_length:int|None=None)->tuple[int,bytes]:
    if type(output_is_null)is not bool or type(input_is_null)is not bool:return -1,b""
    if capacity is not None and (type(capacity)is not int or capacity<0):return -1,b""
    if input_length is not None and (type(input_length)is not int or not 0<=input_length<=MAX_INPUT_LENGTH):return -1,b""
    if input_is_null or not isinstance(values,(list,tuple)):return -1,b""
    if input_length is not None and input_length!=len(values):return -1,b""
    parsed=_parse(values)
    if parsed is None:return -1,b""
    _,m,p,_,routes=parsed;position=[0]*p;trace=[];time=0
    while any(position[i]<len(routes[i][1]) for i in range(p)):
        chosen=[-1]*m
        for packet,(_,route) in enumerate(routes):
            if position[packet]<len(route):
                link=route[position[packet]]
                if chosen[link]<0:chosen[link]=packet
        if not any(packet>=0 for packet in chosen):return -1,b""
        for link,packet in enumerate(chosen):
            if packet>=0:trace.extend((time,link,packet));position[packet]+=1
        time+=1
        if time>MAX_HOPS:return -1,b""
    words=[time,len(trace)//3,*trace];payload=b"".join(struct.pack('<q',x) for x in words)
    if output_is_null or capacity is not None and capacity<len(payload):return -2,b""
    return len(payload),payload
