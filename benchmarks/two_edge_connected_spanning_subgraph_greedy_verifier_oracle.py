"""Independent low-link verifier for the DOI 171 edge-deletion profile."""
from __future__ import annotations

import struct
from collections.abc import Sequence


def _bridges(n: int, edges: list[tuple[int, int]], active: list[bool]) -> set[int]:
    adj: list[list[tuple[int, int]]] = [[] for _ in range(n)]
    for eid, (u, v) in enumerate(edges):
        if active[eid]:
            adj[u].append((v, eid))
            adj[v].append((u, eid))
    disc = [-1] * n
    low = [0] * n
    result: set[int] = set()
    tick = 0

    def dfs(u: int, parent_edge: int) -> None:
        nonlocal tick
        disc[u] = low[u] = tick
        tick += 1
        for v, eid in adj[u]:
            if eid == parent_edge:
                continue
            if disc[v] < 0:
                dfs(v, eid)
                low[u] = min(low[u], low[v])
                if low[v] > disc[u]:
                    result.add(eid)
            else:
                low[u] = min(low[u], disc[v])

    dfs(0, -1)
    return result


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 2 or len(values) > 59 or any(type(x) is not int or not -(1<<63)<=x<(1<<63) for x in values):
        return -1, b""
    n,m=values[0],values[1]
    if not 3<=n<=8 or not 3<=m<=28 or len(values)!=2+2*m:return -1,b""
    edges=[];seen=set()
    for i in range(m):
        u,v=values[2+2*i:4+2*i]
        if not 0<=u<v<n or (u,v) in seen:return -1,b""
        seen.add((u,v));edges.append((u,v))
    alive=[True]*m
    # Connectivity and bridge-freedom define 2-edge-connectivity here.
    def connected() -> bool:
        adj=[[] for _ in range(n)]
        for eid,(u,v) in enumerate(edges):
            if alive[eid]:adj[u].append(v);adj[v].append(u)
        reached={0};stack=[0]
        while stack:
            u=stack.pop()
            for v in adj[u]:
                if v not in reached:reached.add(v);stack.append(v)
        return len(reached)==n
    if not connected() or _bridges(n,edges,alive):return -1,b""
    for i in range(m):
        alive[i]=False
        if not connected() or _bridges(n,edges,alive):alive[i]=True
    kept=sorted(edges[i] for i in range(m) if alive[i])
    payload=struct.pack('<'+'q'*(1+2*len(kept)),len(kept),*(v for e in kept for v in e))
    if output_is_null or capacity is not None and capacity<len(payload):return -2,b""
    return len(payload),payload
