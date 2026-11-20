"""Independent Dijkstra/on-demand reference for the Wulff--Nilsen query."""

from __future__ import annotations

import heapq
import struct

K = 16
MAX_N = 8
MAX_M = 28
MAX_Q = 32
MAX_WEIGHT = 1000
MAX_VALID_INPUT = 166
MAX_PARSEABLE_INPUT = 167
MAX_OUTPUT_BYTES = 520
MAX_WORKSPACE_BYTES = 16384
INVALID_RESULT = -1
OUTPUT_ERROR = -2
INF = 1 << 60
BASE_SPAN = 4


def _parse(values, length, input_is_null):
    if input_is_null or length != len(values) or length < 18 or length > MAX_PARSEABLE_INPUT:
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= m <= MAX_M:
        return None
    masks = values[2:17]
    if len(masks) != 15 or any(x <= 0 or x >= (1 << n) for x in masks):
        return None
    if any(masks[i + 1] & ~masks[i] for i in range(14)):
        return None
    q_at = 17 + 3 * m
    if q_at >= length:
        return None
    q = values[q_at]
    if not 0 <= q <= MAX_Q or length != q_at + 1 + 2 * q:
        return None
    edges = []
    previous = None
    graph = [[] for _ in range(n)]
    for e in range(m):
        u, v, weight = values[17 + 3 * e:20 + 3 * e]
        if not (0 <= u < v < n and 1 <= weight <= MAX_WEIGHT):
            return None
        if previous is not None and (u, v) <= previous:
            return None
        previous = (u, v)
        edges.append((u, v, weight))
        graph[u].append((v, weight))
        graph[v].append((u, weight))
    queries = []
    for qi in range(q):
        u, v = values[q_at + 1 + 2 * qi:q_at + 3 + 2 * qi]
        if not (0 <= u < n and 0 <= v < n):
            return None
        queries.append((u, v))
    return n, masks, graph, queries


def _dijkstra(graph, source):
    distance = [INF] * len(graph)
    distance[source] = 0
    queue = [(0, source)]
    while queue:
        cost, vertex = heapq.heappop(queue)
        if cost != distance[vertex]:
            continue
        for neighbor, weight in graph[vertex]:
            candidate = cost + weight
            if candidate < distance[neighbor]:
                distance[neighbor] = candidate
                heapq.heappush(queue, (candidate, neighbor))
    return distance


def _middle_even(lo, hi):
    return min((x for x in range(lo + 2, hi - 1) if x % 2 == 0),
               key=lambda x: (abs(2 * x - lo - hi), x))


def _solve(parsed):
    n, masks, graph, queries = parsed
    distance = [_dijkstra(graph, source) for source in range(n)]
    if any(distance[i][j] == INF for i in range(n) for j in range(n)):
        return None
    nearest = [[vertex for _ in range(n)] for vertex in range(K)]
    for source in range(n):
        nearest[0][source] = source
    for level in range(1, K):
        candidates = [v for v in range(n) if masks[level - 1] >> v & 1]
        for source in range(n):
            nearest[level][source] = min(candidates, key=lambda v: (distance[source][v], v))

    # Construct each bunch by testing the source definition's level differences.
    all_vertices = (1 << n) - 1
    sets = [all_vertices, *masks, 0]
    bunch = [[False] * n for _ in range(n)]
    for source in range(n):
        for level in range(K):
            next_layer = [v for v in range(n) if sets[level + 1] >> v & 1]
            boundary = min((distance[source][v] for v in next_layer), default=INF)
            for vertex in range(n):
                if sets[level] >> vertex & 1 and not (sets[level + 1] >> vertex & 1):
                    if distance[source][vertex] < boundary:
                        bunch[source][vertex] = True

    def dist_k(u, v, start):
        level = start
        probes = 0
        while True:
            pivot = nearest[level][u]
            probes += 1
            if bunch[v][pivot]:
                return distance[u][pivot] + distance[v][pivot], probes
            u, v = v, u
            level += 1
            if level >= K:
                raise AssertionError("A15 membership must terminate dist_k")

    def recursively_query(u, v, lo, hi):
        if hi - lo <= BASE_SPAN:
            return dist_k(u, v, lo)
        mid = _middle_even(lo, hi)
        gaps = []
        for level in range(lo, mid - 1, 2):
            gaps.append((distance[u][nearest[level + 2][u]] -
                         distance[u][nearest[level][u]], level))
        maximum = max(gap for gap, _ in gaps)
        j = min(level for gap, level in gaps if gap == maximum)
        first = bunch[v][nearest[j][u]]
        second = bunch[u][nearest[j + 1][v]]
        probes = 2
        child = (mid, hi) if not first and not second else (lo, j)
        estimate, tail = recursively_query(u, v, *child)
        return estimate, probes + tail

    staged = [len(queries)]
    for source, target in queries:
        if source == target:
            staged.extend((0, 0))
            continue
        estimate, probes = recursively_query(source, target, 0, K - 1)
        staged.extend((estimate, probes))
    return tuple(staged)


def expected_output(values, output_capacity=MAX_OUTPUT_BYTES, output_is_null=False,
                    input_is_null=False, input_length=None):
    values = tuple(values)
    if input_length is None:
        input_length = len(values)
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return INVALID_RESULT, b""
    staged = _solve(parsed)
    if staged is None:
        return INVALID_RESULT, b""
    encoded = b"".join(struct.pack("<q", word) for word in staged)
    if output_is_null or output_capacity < len(encoded):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
