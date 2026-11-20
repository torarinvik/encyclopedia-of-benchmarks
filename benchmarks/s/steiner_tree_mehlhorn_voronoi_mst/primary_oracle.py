"""Clean-room bounded Mehlhorn Voronoi/MST Steiner-tree reference."""
from __future__ import annotations

import heapq
import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 14
MAX_VALID_INPUT_LENGTH = 3 + MAX_N + 3 * MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (2 + MAX_N - 1)
MAX_WORKSPACE_BYTES = 8192
WORKSPACE_BYTES = MAX_WORKSPACE_BYTES
SYMBOL = "steiner_tree_mehlhorn_voronoi_mst"
INF = 1 << 60


def _decode(values: Sequence[int]):
    if not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return None
    n, m, k = values[:3]
    if not 2 <= n <= MAX_N or not 1 <= m <= MAX_M or not 2 <= k <= n:
        return None
    if len(values) < 3 + k + 3 * m:
        return None
    terminals = list(values[3 : 3 + k])
    if any(not 0 <= t < n for t in terminals) or len(set(terminals)) != k:
        return None
    edges: list[tuple[int, int, int]] = []
    seen: set[tuple[int, int]] = set()
    at = 3 + k
    for _ in range(m):
        u, v, w = values[at : at + 3]
        at += 3
        if not (0 <= u < v < n) or not 1 <= w <= 9 or (u, v) in seen:
            return None
        seen.add((u, v))
        edges.append((u, v, w))
    if at != len(values):
        return None
    adj = [[] for _ in range(n)]
    for edge_id, (u, v, w) in enumerate(edges):
        adj[u].append((v, edge_id, w))
        adj[v].append((u, edge_id, w))
    reached = {0}
    stack = [0]
    while stack:
        u = stack.pop()
        for v, _, _ in adj[u]:
            if v not in reached:
                reached.add(v)
                stack.append(v)
    if len(reached) != n:
        return None
    return n, m, terminals, edges, adj


def _dijkstra(n, terminals, adj):
    dist = [INF] * n
    owner = [n] * n
    pred = [-1] * n
    pred_edge = [-1] * n
    settled = [False] * n
    heap = []
    for t in terminals:
        dist[t] = 0
        owner[t] = t
        heapq.heappush(heap, (0, t, t))
    while heap:
        d, src, u = heapq.heappop(heap)
        if settled[u] or (d, src) != (dist[u], owner[u]):
            continue
        settled[u] = True
        for v, edge_id, weight in adj[u]:
            nd = d + weight
            if nd < dist[v] or (nd == dist[v] and src < owner[v]):
                dist[v], owner[v] = nd, src
                pred[v], pred_edge[v] = u, edge_id
                heapq.heappush(heap, (nd, src, v))
            elif nd == dist[v] and src == owner[v] and not settled[v]:
                if pred[v] < 0 or (u, edge_id) < (pred[v], pred_edge[v]):
                    pred[v], pred_edge[v] = u, edge_id
    return dist, owner, pred, pred_edge


def _find(parent, x):
    while parent[x] != x:
        parent[x] = parent[parent[x]]
        x = parent[x]
    return x


def _union(parent, rank, a, b):
    ra, rb = _find(parent, a), _find(parent, b)
    if ra == rb:
        return False
    if rank[ra] < rank[rb]:
        ra, rb = rb, ra
    parent[rb] = ra
    if rank[ra] == rank[rb]:
        rank[ra] += 1
    return True


def _solve(graph):
    n, m, terminals, edges, adj = graph
    dist, owner, pred, pred_edge = _dijkstra(n, terminals, adj)
    # One minimum witness edge per unordered terminal pair.
    candidates = {}
    for edge_id, (u, v, weight) in enumerate(edges):
        a, b = owner[u], owner[v]
        if a == b:
            continue
        if a > b:
            a, b = b, a
            left, right = v, u
        else:
            left, right = u, v
        key = (dist[u] + weight + dist[v], left, right, edge_id)
        old = candidates.get((a, b))
        if old is None or key < old:
            candidates[(a, b)] = key

    ordered = sorted((value[0], a, b, value[1], value[2], value[3])
                     for (a, b), value in candidates.items())
    parent = list(range(n))
    rank = [0] * n
    chosen = []
    for weight, a, b, left, right, edge_id in ordered:
        if _union(parent, rank, a, b):
            chosen.append((a, b, left, right, edge_id))
    if len(chosen) != len(terminals) - 1:
        return None

    used = [False] * m
    for a, b, left, right, cross_edge in chosen:
        used[cross_edge] = True
        x = left
        while x != a:
            if x < 0 or pred_edge[x] < 0:
                return None
            used[pred_edge[x]] = True
            x = pred[x]
        x = right
        while x != b:
            if x < 0 or pred_edge[x] < 0:
                return None
            used[pred_edge[x]] = True
            x = pred[x]

    union_edges = [e for e in range(m) if used[e]]
    parent = list(range(n))
    rank = [0] * n
    tree = []
    for edge_id in sorted(union_edges, key=lambda e: (edges[e][2], e)):
        u, v, _ = edges[edge_id]
        if _union(parent, rank, u, v):
            tree.append(edge_id)
    # The expanded terminal MST need only span the vertices used by its paths;
    # isolated input vertices are intentionally absent from this tree.
    root = _find(parent, terminals[0])
    if any(_find(parent, t) != root for t in terminals):
        return None

    degree = [0] * n
    incident = [[] for _ in range(n)]
    keep = [False] * m
    for edge_id in tree:
        keep[edge_id] = True
        u, v, _ = edges[edge_id]
        degree[u] += 1
        degree[v] += 1
        incident[u].append(edge_id)
        incident[v].append(edge_id)
    terminal_set = set(terminals)
    queue = [v for v in range(n) if v not in terminal_set and degree[v] <= 1]
    head = 0
    while head < len(queue):
        u = queue[head]
        head += 1
        if degree[u] > 1:
            continue
        for edge_id in incident[u]:
            if not keep[edge_id]:
                continue
            keep[edge_id] = False
            a, b, _ = edges[edge_id]
            v = b if a == u else a
            degree[u] -= 1
            degree[v] -= 1
            if v not in terminal_set and degree[v] <= 1:
                queue.append(v)
    result_edges = [e for e in range(m) if keep[e]]
    if not result_edges:
        return None
    cost = sum(edges[e][2] for e in result_edges)
    return cost, result_edges


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or
                                     not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    graph = _decode(values)
    if graph is None:
        return -1, b""
    answer = _solve(graph)
    if answer is None:
        return -1, b""
    cost, edge_ids = answer
    payload = struct.pack("<" + "q" * (2 + len(edge_ids)), cost, len(edge_ids), *edge_ids)
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
