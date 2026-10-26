"""Independent Dijkstra-based verifier for the bounded k=2 oracle profile."""

from __future__ import annotations

import heapq
import struct

MAX_VERTICES = 12
MAX_EDGES = MAX_VERTICES * (MAX_VERTICES - 1) // 2
MAX_QUERIES = 32
MAX_WEIGHT = 1_000
MAX_INPUT_LENGTH = 4 + 3 * MAX_EDGES + 2 * MAX_QUERIES
MAX_OUTPUT_BYTES = 8 * (MAX_QUERIES + 1)
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _graph(values: tuple[int, ...]):
    n, m, sample_mask = values[:3]
    q_at = 3 + 3 * m
    q = values[q_at]
    graph = [[] for _ in range(n)]
    for edge in range(m):
        u, v, w = values[3 + 3 * edge:6 + 3 * edge]
        graph[u].append((v, w))
        graph[v].append((u, w))
    return n, sample_mask, q_at, q, graph


def _dijkstra(graph, source: int) -> tuple[int, ...]:
    distance = [10**18] * len(graph)
    distance[source] = 0
    heap = [(0, source)]
    while heap:
        d, u = heapq.heappop(heap)
        if d != distance[u]:
            continue
        for v, w in graph[u]:
            candidate = d + w
            if candidate < distance[v]:
                distance[v] = candidate
                heapq.heappush(heap, (candidate, v))
    return tuple(distance)


def _valid(values: tuple[int, ...], input_length: int, input_is_null: bool) -> bool:
    if input_is_null or input_length != len(values) or not 4 <= input_length <= MAX_INPUT_LENGTH:
        return False
    n, m, mask = values[:3]
    if not 1 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES or not 0 < mask < 1 << n:
        return False
    q_at = 3 + 3 * m
    if q_at >= len(values):
        return False
    q = values[q_at]
    if not 0 <= q <= MAX_QUERIES or len(values) != q_at + 1 + 2 * q:
        return False
    pairs=set()
    graph=[[] for _ in range(n)]
    for i in range(m):
        u,v,w=values[3+3*i:6+3*i]
        if not (0 <= u < v < n and 1 <= w <= MAX_WEIGHT) or (u,v) in pairs:
            return False
        pairs.add((u,v)); graph[u].append(v); graph[v].append(u)
    if n>1:
        seen={0}; pending=[0]
        while pending:
            u=pending.pop()
            for v in graph[u]:
                if v not in seen: seen.add(v); pending.append(v)
        if len(seen)!=n: return False
    return all(0 <= values[q_at+1+2*i] < n and 0 <= values[q_at+2+2*i] < n for i in range(q))


def expected_output(values, output_capacity=MAX_OUTPUT_BYTES, output_is_null=False,
                    input_is_null=False, input_length=None):
    values=tuple(values)
    if input_length is None: input_length=len(values)
    if not _valid(values,input_length,input_is_null): return INVALID_RESULT,b""
    n,mask,q_at,q,graph=_graph(values)
    sample=[v for v in range(n) if mask>>v&1]
    all_dist=[_dijkstra(graph,v) for v in range(n)]
    nearest=[min(sample,key=lambda a:(all_dist[v][a],a)) for v in range(n)]
    bunch=[]
    for u in range(n):
        threshold=all_dist[u][nearest[u]]
        row=set(sample)
        row.update(x for x in range(n) if not(mask>>x&1) and all_dist[u][x]<threshold)
        bunch.append(row)
    estimates=[]
    for query in range(q):
        u,v=values[q_at+1+2*query:q_at+3+2*query]
        level=0
        while True:
            pivot=v if level==0 else nearest[v]
            if pivot in bunch[u]:
                estimates.append(all_dist[u][pivot]+all_dist[v][pivot]); break
            u,v=v,u; level+=1
    result=b"".join(struct.pack("<q",x) for x in (len(estimates),*estimates))
    if output_is_null or output_capacity<len(result): return OUTPUT_ERROR,b""
    return len(result),result
