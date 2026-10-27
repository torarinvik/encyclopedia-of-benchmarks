"""Independent verifier using frozensets of (node, FF-delay) elements."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from itertools import product

MAX_INPUT_LENGTH = 12


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool: return -1,b""
    if capacity is not None and (type(capacity) is not int or capacity<0): return -1,b""
    if input_length is not None and (type(input_length) is not int or not 0<=input_length<=MAX_INPUT_LENGTH): return -1,b""
    if input_is_null or not isinstance(values,(list,tuple)): return -1,b""
    if input_length is not None and len(values)!=input_length:return -1,b""
    if not 3<=len(values)<=MAX_INPUT_LENGTH or any(type(x)is not int or not -(1<<63)<=x<(1<<63) for x in values):return -1,b""
    n,k,m=values[:3]
    if not 1<=n<=3 or not 1<=k<=2 or not 0<=m<=3 or len(values)!=3+3*m:return -1,b""
    incoming=[[] for _ in range(n)];seen=set()
    for i in range(m):
        u,v,d=values[3+3*i:6+3*i]
        if not (0<=u<v<n) or d not in (0,1) or (u,v,d) in seen:return -1,b""
        seen.add((u,v,d));incoming[v].append((u,d))
    cuts:list[list[frozenset[tuple[int,int]]]]=[]
    for v in range(n):
        result={frozenset({(v,0)})}
        edge_options=[]
        for u,delay in incoming[v]:
            edge_options.append([
                frozenset((node,offset+delay) for node,offset in prior)
                for prior in cuts[u]
            ])
        if edge_options:
            for selected in product(*edge_options):
                merged=frozenset().union(*selected)
                if len(merged)<=k: result.add(merged)
        cuts.append(sorted(result,key=lambda s:tuple(sorted(s))))
    words=[n]
    for row in cuts:
        encoded=[]
        for cut in row:
            mask=0
            for node,delay in cut:
                if delay>2:return -1,b""
                mask |= 1<<(3*node+delay)
            encoded.append(mask)
        words.append(len(row));words.extend(sorted(encoded))
    payload=b"".join(struct.pack("<q",x) for x in words)
    if output_is_null or capacity is not None and capacity<len(payload):return -2,b""
    return len(payload),payload
