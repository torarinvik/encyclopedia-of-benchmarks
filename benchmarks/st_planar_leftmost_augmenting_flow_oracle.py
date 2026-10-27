"""Cut-enumeration oracle for the bounded st-planar leftmost-flow profile."""
from __future__ import annotations
import struct
from collections.abc import Sequence
MAX_INPUT_LENGTH = 60
MAX_OUTPUT_BYTES = 8
MAX_N = 6
MAX_M = 10

def _parse(values: Sequence[int]):
    if not 4 <= len(values) <= MAX_INPUT_LENGTH or any(type(x) is not int or not -(1<<63) <= x < (1<<63) for x in values):
        return None
    n,m,s,t=values[:4]
    if not 2<=n<=MAX_N or not 1<=m<=MAX_M or not 0<=s<n or not 0<=t<n or s==t:
        return None
    at=4
    if len(values)<4+3*m: return None
    edges=[]; pairs=set()
    for e in range(m):
        u,v,c=values[at:at+3];at+=3
        pair=(min(u,v),max(u,v))
        if not (0<=u<n and 0<=v<n and u!=v and 0<=c<=5) or pair in pairs: return None
        pairs.add(pair);edges.append((u,v,c))
    rotations=[];occ=[[0,0] for _ in range(m)]
    for v in range(n):
        if at>=len(values): return None
        d=values[at];at+=1
        if not 0<=d<=MAX_N-1 or at+d>len(values): return None
        row=list(values[at:at+d]);at+=d
        if len(set(row))!=d:return None
        for e in row:
            if not 0<=e<m:return None
            u,w,_=edges[e]
            if v==u:occ[e][0]+=1
            elif v==w:occ[e][1]+=1
            else:return None
        rotations.append(row)
    if at!=len(values) or any(x!=[1,1] for x in occ):return None
    # The profile accepts a connected supplied embedding as a source precondition.
    seen={s};stack=[s]
    while stack:
        u=stack.pop()
        for a,b,_ in edges:
            if a==u and b not in seen:seen.add(b);stack.append(b)
            if b==u and a not in seen:seen.add(a);stack.append(a)
    if len(seen)!=n:return None
    return n,m,s,t,edges,rotations

def expected_output(values: Sequence[int] | None, capacity: int | None=None,
                    output_is_null: bool=False, input_is_null: bool=False,
                    input_length: int | None=None) -> tuple[int,bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:return -1,b""
    if capacity is not None and (type(capacity) is not int or capacity<0):return -1,b""
    if input_length is not None and (type(input_length) is not int or not 0<=input_length<=MAX_INPUT_LENGTH):return -1,b""
    if input_is_null or values is None or not isinstance(values,(list,tuple)):return -1,b""
    if input_length is not None and input_length!=len(values):return -1,b""
    parsed=_parse(values)
    if parsed is None:return -1,b""
    n,m,s,t,edges,_=parsed
    best=None
    for mask in range(1<<n):
        if not (mask>>s)&1 or (mask>>t)&1:continue
        cut=sum(c for u,v,c in edges if (mask>>u)&1 and not ((mask>>v)&1))
        if best is None or cut<best:best=cut
    payload=struct.pack('<q',best or 0)
    if output_is_null or capacity is not None and capacity<len(payload):return -2,b""
    return len(payload),payload
