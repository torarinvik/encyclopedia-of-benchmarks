"""Independent edge-coverage-state Dijkstra oracle for route inspection."""

from __future__ import annotations

from heapq import heappop, heappush


def expected_result(values: list[int]) -> int:
    if len(values) < 2:
        return -1
    n, m = values[:2]
    if not (1 <= n <= 8 and 0 <= m <= 12 and len(values) == 2 + 3 * m):
        return -1

    edges: list[tuple[int, int, int]] = []
    adjacency: list[list[tuple[int, int, int]]] = [[] for _ in range(n)]
    seen: set[tuple[int, int]] = set()
    for edge_id in range(m):
        offset = 2 + edge_id * 3
        u, v, weight = values[offset : offset + 3]
        if not (0 <= u < n and 0 <= v < n and u != v and 1 <= weight <= 1000):
            return -1
        pair = (u, v) if u < v else (v, u)
        if pair in seen:
            return -1
        seen.add(pair)
        edges.append((u, v, weight))
        bit = 1 << edge_id
        adjacency[u].append((v, weight, bit))
        adjacency[v].append((u, weight, bit))

    if n == 1:
        return 0 if m == 0 else -1
    if m < n - 1:
        return -1
    reached = {0}
    todo = [0]
    while todo:
        u = todo.pop()
        for v, _, _ in adjacency[u]:
            if v not in reached:
                reached.add(v)
                todo.append(v)
    if len(reached) != n:
        return -1

    full_mask = (1 << m) - 1
    infinity = 1 << 60
    distances = [[infinity] * (1 << m) for _ in range(n)]
    distances[0][0] = 0
    queue = [(0, 0, 0)]
    while queue:
        cost, vertex, mask = heappop(queue)
        if cost != distances[vertex][mask]:
            continue
        if vertex == 0 and mask == full_mask:
            return cost
        for neighbor, weight, edge_bit in adjacency[vertex]:
            next_mask = mask | edge_bit
            next_cost = cost + weight
            if next_cost < distances[neighbor][next_mask]:
                distances[neighbor][next_mask] = next_cost
                heappush(queue, (next_cost, neighbor, next_mask))
    return -1
