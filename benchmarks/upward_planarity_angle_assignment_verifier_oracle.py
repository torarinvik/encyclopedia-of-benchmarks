"""Independent assignment-enumeration oracle for DOI 653 profile."""
from __future__ import annotations

import struct
from collections import deque
from collections.abc import Sequence

MAX_INPUT_LENGTH = 124
MAX_OUTPUT_BYTES = 208


def _decode(a: Sequence[int] | None):
    if not isinstance(a, (tuple, list)) or not 4 <= len(a) <= MAX_INPUT_LENGTH:
        return None
    if any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in a): return None
    n,m,f,o=a[:4]
    if not 2<=n<=8 or not 1<=m<=18 or not 1<=f<=12 or not 0<=o<f or len(a)!=4+6*m+f: return None
    edges=[]; und=set()
    for i in range(m):
        u,v=a[4+2*i:6+2*i]
        if not (0<=u<n and 0<=v<n and u!=v) or (edges and edges[-1]>=(u,v)): return None
        e=(min(u,v),max(u,v))
        if e in und:return None
        und.add(e);edges.append((u,v))
    edge_set=set(edges); faces=[]; cursor=4+2*m; darts=set()
    for _ in range(f):
        k=a[cursor];cursor+=1
        if k<1 or cursor+2*k>len(a):return None
        w=[]
        for j in range(k):
            u,v=a[cursor:cursor+2];cursor+=2
            if (u,v) not in edge_set and (v,u) not in edge_set:return None
            if (u,v) in darts:return None
            darts.add((u,v));w.append((u,v))
        if any(w[i][1]!=w[(i+1)%k][0] for i in range(k)):return None
        faces.append(w)
    if cursor!=len(a) or len(darts)!=2*m or n-m+f!=2:return None
    if any((u,v) not in darts or (v,u) not in darts for u,v in edges):return None
    return n,edges,faces,o


def _solve(d):
    n,edges,faces,outer=d
    out=[set() for _ in range(n)]; und=[set() for _ in range(n)]; indeg=[0]*n
    for u,v in edges:out[u].add(v);und[u].add(v);und[v].add(u);indeg[v]+=1
    seen={0}; stack=[0]
    while stack:
        u=stack.pop()
        for v in und[u]-seen:seen.add(v);stack.append(v)
    if len(seen)!=n:return None
    deg=indeg[:]; q=deque(i for i,x in enumerate(deg) if x==0); top=[]
    while q:
        u=q.popleft();top.append(u)
        for v in out[u]:deg[v]-=1; q.append(v) if deg[v]==0 else None
    if len(top)!=n:return None
    succ=[{} for _ in range(n)]; corners=[{} for _ in faces]; inc=[set() for _ in range(n)]; st=[[0,0] for _ in faces]
    for fi,w in enumerate(faces):
        for j,(u,v) in enumerate(w):
            z=w[(j+1)%len(w)][1]
            if u in succ[v]:return None
            succ[v][u]=z;corners[fi].setdefault(v,j);inc[v].add(fi)
            x=u in out[v];y=z in out[v]
            if x and y:st[fi][0]+=1
            if not x and not y:st[fi][1]+=1
    for v in range(n):
        if set(succ[v])!=und[v] or set(succ[v].values())!=und[v]:return None
        if und[v]:
            cur=min(und[v]);seenv=set()
            while cur not in seenv:seenv.add(cur);cur=succ[v][cur]
            if cur!=min(und[v]) or len(seenv)!=len(und[v]):return None
            changes=sum((x in out[v])!=(succ[v][x] in out[v]) for x in und[v])
            if changes not in (0,2):return None
    if any(x!=y for x,y in st):return None
    caps=[x+1 if i==outer else x-1 for i,(x,_) in enumerate(st)]
    terminals=[v for v in range(n) if indeg[v]==0 or not out[v]]
    r=len(terminals)
    if any(c<0 for c in caps) or sum(caps)!=r:return [0,r]+[-1,-1,-1]*r
    # Enumerate face choices directly; unlike the primary oracle, no slot matching.
    remaining=caps[:]; chosen=[-1]*r
    def visit(k):
        if k==r:return True
        v=terminals[k]
        for fi in sorted(inc[v]):
            if remaining[fi]:
                remaining[fi]-=1;chosen[k]=fi
                if visit(k+1):return True
                remaining[fi]+=1
        return False
    if not visit(0):return [0,r]+[-1,-1,-1]*r
    ans=[1,r]
    for v,fi in zip(terminals,chosen):ans.extend((v,fi,corners[fi][v]))
    return ans


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
        or capacity is not None and (type(capacity) is not int or capacity<0)
        or input_length is not None and (type(input_length) is not int or input_length<0)
        or input_is_null and values not in (None,[],())
        or not input_is_null and values is not None and input_length is not None and input_length!=len(values)):
        return -1,b""
    d=None if input_is_null else _decode(values)
    if d is None:return -1,b""
    words=_solve(d)
    if words is None:return -1,b""
    payload=struct.pack("<"+"q"*len(words),*words)
    if output_is_null or capacity is not None and capacity<len(payload):return -2,b""
    return len(payload),payload
