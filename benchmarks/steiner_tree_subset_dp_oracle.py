"""Primary terminal-subset dynamic-programming oracle for exact graph Steiner trees."""

from __future__ import annotations

import heapq
from collections.abc import Sequence

MAX_VERTICES = 8
MAX_EDGES = 14
MAX_TERMINALS = 5
MAX_INPUT_LENGTH = 50
INF = 1 << 60


def _parse(values: Sequence[int] | None) -> tuple[int, list[tuple[int, int, int]], list[int]] | None:
    if not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, m, k = values[:3]
    if not 1 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES or not 1 <= k <= min(MAX_TERMINALS, n):
        return None
    if m > n * (n - 1) // 2 or len(values) != 3 + k + 3 * m:
        return None
    terminals = list(values[3:3 + k])
    if any(not 0 <= vertex < n for vertex in terminals) or len(set(terminals)) != k:
        return None
    edges: list[tuple[int, int, int]] = []
    seen: set[tuple[int, int]] = set()
    at = 3 + k
    for _ in range(m):
        u, v, weight = values[at:at + 3]
        at += 3
        if not (0 <= u < v < n and 0 <= weight <= 1000) or (u, v) in seen:
            return None
        seen.add((u, v))
        edges.append((u, v, weight))
    return n, edges, terminals


def expected_result(values: Sequence[int] | None) -> int:
    parsed = _parse(values)
    if parsed is None:
        return -1
    n, edges, terminals = parsed
    k = len(terminals)
    masks = 1 << k
    adjacency: list[list[tuple[int, int]]] = [[] for _ in range(n)]
    for u, v, weight in edges:
        adjacency[u].append((v, weight))
        adjacency[v].append((u, weight))

    # dp[mask][v] is the minimum cost of a connected subgraph containing
    # every terminal in mask and rooted at v.
    dp = [[INF] * n for _ in range(masks)]
    for bit, vertex in enumerate(terminals):
        dp[1 << bit][vertex] = 0

    for mask in range(1, masks):
        if mask & (mask - 1):
            sub = (mask - 1) & mask
            while sub:
                other = mask ^ sub
                if sub < other:
                    left, right = dp[sub], dp[other]
                    row = dp[mask]
                    for vertex in range(n):
                        candidate = left[vertex] + right[vertex]
                        if candidate < row[vertex]:
                            row[vertex] = candidate
                sub = (sub - 1) & mask

        row = dp[mask]
        queue = [(cost, vertex) for vertex, cost in enumerate(row) if cost < INF]
        heapq.heapify(queue)
        while queue:
            cost, vertex = heapq.heappop(queue)
            if cost != row[vertex]:
                continue
            for neighbor, weight in adjacency[vertex]:
                candidate = cost + weight
                if candidate < row[neighbor]:
                    row[neighbor] = candidate
                    heapq.heappush(queue, (candidate, neighbor))

    answer = min(dp[-1])
    return -2 if answer >= INF else answer
