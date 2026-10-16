"""Bounded state-based grow-only counter CRDT trace oracle."""
from __future__ import annotations
MAX_NODES=8
MAX_OPERATIONS=128
MAX_INPUT_LENGTH=2+3*MAX_OPERATIONS
MAX_COMPONENT=1_000_000
INVALID_RESULT=-1
MASK=(1<<64)-1
OFFSET=0xCBF29CE484222325
PRIME=0x100000001B3

def _hash(h:int,value:int)->int:
    bits=value&MASK
    for shift in range(0,64,8): h=((h^((bits>>shift)&255))*PRIME)&MASK
    return h

def expected_result(values:list[int])->int:
    if (not isinstance(values,(list,tuple)) or len(values)<2 or len(values)>MAX_INPUT_LENGTH
        or any(type(x)is not int or not -(1<<63)<=x<(1<<63) for x in values)):
        return INVALID_RESULT
    n,count=values[:2]
    if not 1<=n<=MAX_NODES or not 0<=count<=MAX_OPERATIONS or len(values)!=2+3*count:return INVALID_RESULT
    states=[[0]*n for _ in range(n)]
    h=OFFSET
    for index in range(count):
        op,a,b=values[2+3*index:5+3*index]
        if not 0<=a<n:return INVALID_RESULT
        if op==0:
            if b!=0 or states[a][a]>=MAX_COMPONENT:return INVALID_RESULT
            states[a][a]+=1
        elif op==1:
            if b!=0:return INVALID_RESULT
            h=_hash(h,sum(states[a]))
        elif op==2:
            if not 0<=b<n:return INVALID_RESULT
            h=_hash(h,int(all(states[a][i]<=states[b][i] for i in range(n))))
        elif op==3:
            if not 0<=b<n:return INVALID_RESULT
            states[a]=[max(states[a][i],states[b][i]) for i in range(n)]
        else:return INVALID_RESULT
    for row in states:
        for component in row:h=_hash(h,component)
    return h if h<(1<<63) else h-(1<<64)
