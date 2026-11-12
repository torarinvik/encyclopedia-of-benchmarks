"""Primary shortest-path plus odd-vertex pairing oracle for route inspection."""

from __future__ import annotations

from functools import lru_cache


MAX_VERTICES = 8
MAX_EDGES = 12
MAX_WEIGHT = 1000
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_EDGES
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1


def _parse(values: list[int]) -> tuple[int, list[tuple[int, int, int]]] | None:
    if len(values) < 2:
        return None
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES:
        return None
    if len(values) != 2 + 3 * m:
        return None

    edges: list[tuple[int, int, int]] = []
    seen: set[tuple[int, int]] = set()
    degree = [0] * n
    for index in range(m):
        u, v, weight = values[2 + 3 * index : 5 + 3 * index]
        if not (0 <= u < n and 0 <= v < n and u != v):
            return None
        if not 1 <= weight <= MAX_WEIGHT:
            return None
        pair = (min(u, v), max(u, v))
        if pair in seen:
            return None
        seen.add(pair)
        degree[u] += 1
        degree[v] += 1
        edges.append((u, v, weight))

    if n == 1:
        return (n, edges) if m == 0 else None
    if m < n - 1:
        return None
    reached = {0}
    adjacency = [[] for _ in range(n)]
    for u, v, _ in edges:
        adjacency[u].append(v)
        adjacency[v].append(u)
    stack = [0]
    while stack:
        u = stack.pop()
        for v in adjacency[u]:
            if v not in reached:
                reached.add(v)
                stack.append(v)
    if len(reached) != n:
        return None
    return n, edges


def expected_result(values: list[int]) -> int:
    """Return the minimum closed route length, or -1 for invalid input."""
    parsed = _parse(values)
    if parsed is None:
        return -1
    n, edges = parsed
    if n == 1:
        return 0

    infinity = 1 << 60
    distance = [[infinity] * n for _ in range(n)]
    degree = [0] * n
    total_weight = 0
    for u in range(n):
        distance[u][u] = 0
    for u, v, weight in edges:
        distance[u][v] = distance[v][u] = weight
        degree[u] += 1
        degree[v] += 1
        total_weight += weight

    for middle in range(n):
        for source in range(n):
            through = distance[source][middle]
            for target in range(n):
                candidate = through + distance[middle][target]
                if candidate < distance[source][target]:
                    distance[source][target] = candidate

    odd = [vertex for vertex, value in enumerate(degree) if value & 1]
    pair_count = len(odd)

    @lru_cache(maxsize=None)
    def pair_cost(mask: int) -> int:
        if mask == 0:
            return 0
        first_bit = mask & -mask
        first = first_bit.bit_length() - 1
        remaining = mask ^ first_bit
        best = infinity
        choices = remaining
        while choices:
            partner_bit = choices & -choices
            partner = partner_bit.bit_length() - 1
            candidate = distance[odd[first]][odd[partner]] + pair_cost(
                remaining ^ partner_bit
            )
            if candidate < best:
                best = candidate
            choices ^= partner_bit
        return best

    return total_weight + pair_cost((1 << pair_count) - 1)
