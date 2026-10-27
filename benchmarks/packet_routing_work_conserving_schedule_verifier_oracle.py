"""Independent per-time link-queue oracle for packet-routing traces."""
from __future__ import annotations
import struct
from collections.abc import Sequence
MAX_INPUT_LENGTH=99
MAX_OUTPUT_BYTES=1360

def decode(words):
    if not 3<=len(words)<=MAX_INPUT_LENGTH or any(type(x)is not int or not -(1<<63)<=x<(1<<63) for x in words):return None
    n,m,p=words[:3]
    if not 2<=n<=8 or not 1<=m<=12 or not 1<=p<=8:return None
    pos=3
    if pos+2*m>len(words):return None
    links=[];link_pairs=set()
    for _ in range(m):
        a,b=words[pos:pos+2];pos+=2;key=tuple(sorted((a,b)))
        if not 0<=a<n or not 0<=b<n or a==b or key in link_pairs:return None
        link_pairs.add(key);links.append((a,b))
    routes=[]
    for _ in range(p):
        if pos+2>len(words):return None
        current=words[pos];length=words[pos+1];pos+=2
        if not 0<=current<n or not 1<=length<n or pos+length>len(words):return None
        route=tuple(words[pos:pos+length]);pos+=length
        if any(e<0 or e>=m for e in route) or len(set(route))!=length:return None
        nodes={current}
        for e in route:
            u,v=links[e]
            if current==u:current=v
            elif current==v:current=u
            else:return None
            if current in nodes:return None
            nodes.add(current)
        routes.append(route)
    if pos!=len(words):return None
    return links,routes

def expected_output(values:Sequence[int]|None,capacity:int|None=None,output_is_null:bool=False,input_is_null:bool=False,input_length:int|None=None)->tuple[int,bytes]:
    if type(output_is_null)is not bool or type(input_is_null)is not bool:return -1,b""
    if capacity is not None and (type(capacity)is not int or capacity<0):return -1,b""
    if input_length is not None and (type(input_length)is not int or not 0<=input_length<=MAX_INPUT_LENGTH):return -1,b""
    if input_is_null or not isinstance(values,(list,tuple)):return -1,b""
    if input_length is not None and len(values)!=input_length:return -1,b""
    parsed=decode(values)
    if parsed is None:return -1,b""
    links,routes=parsed;cursor=[0]*len(routes);records=[];clock=0
    while True:
        link_queues=[[] for _ in links]
        for packet,path in enumerate(routes):
            if cursor[packet]<len(path):link_queues[path[cursor[packet]]].append(packet)
        if not any(link_queues):break
        sends=[]
        for link,queue in enumerate(link_queues):
            if queue:sends.append((link,min(queue)))
        for link,packet in sends:records.append((clock,link,packet));cursor[packet]+=1
        clock+=1
        if clock>56:return -1,b""
    payload=struct.pack('<'+'q'*(2+3*len(records)),clock,len(records),*(x for rec in records for x in rec))
    if output_is_null or capacity is not None and capacity<len(payload):return -2,b""
    return len(payload),payload
