"""Reference semantics for forest edge deletions and connectivity queries."""
from __future__ import annotations

MAX_VERTICES = 32
MAX_OPERATIONS = 128
MAX_INPUT_LENGTH = 3 + 2 * (MAX_VERTICES - 1) + 3 * MAX_OPERATIONS
INVALID_RESULT = -1
MASK64 = (1 << 64) - 1


def expected_result(values: list[int]) -> int:
    if not isinstance(values, list) or len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return INVALID_RESULT
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_VERTICES or not 0 <= m <= n - 1:
        return INVALID_RESULT
    edge_end = 2 + 2 * m
    if len(values) <= edge_end:
        return INVALID_RESULT
    q = values[edge_end]
    if not 0 <= q <= MAX_OPERATIONS or len(values) != edge_end + 1 + 3 * q:
        return INVALID_RESULT
    adjacency = [0] * n
    parent = list(range(n))
    def find(x: int) -> int:
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x
    for p in range(2, edge_end, 2):
        u, v = values[p:p+2]
        if not 0 <= u < n or not 0 <= v < n or u == v or (adjacency[u] >> v) & 1:
            return INVALID_RESULT
        a, b = find(u), find(v)
        if a == b:
            return INVALID_RESULT
        parent[b] = a
        adjacency[u] |= 1 << v
        adjacency[v] |= 1 << u
    component = [-1] * n
    next_component = 0
    for start in range(n):
        if component[start] >= 0:
            continue
        component[start] = next_component
        stack = [start]
        while stack:
            u = stack.pop()
            for v in range(n):
                if (adjacency[u] >> v) & 1 and component[v] < 0:
                    component[v] = next_component
                    stack.append(v)
        next_component += 1
    h = 14695981039346656037
    for k in range(q):
        p = edge_end + 1 + 3*k
        op, u, v = values[p:p+3]
        if op not in (0, 1) or not 0 <= u < n or not 0 <= v < n:
            return INVALID_RESULT
        if op == 1:
            h ^= int(component[u] == component[v])
            h = (h * 1099511628211) & MASK64
            continue
        if not ((adjacency[u] >> v) & 1) or component[u] != component[v]:
            return INVALID_RESULT
        adjacency[u] &= ~(1 << v)
        adjacency[v] &= ~(1 << u)
        def side(start: int) -> list[int]:
            found = {start}
            todo = [start]
            while todo:
                x = todo.pop()
                for y in range(n):
                    if ((adjacency[x] >> y) & 1) and y not in found:
                        found.add(y)
                        todo.append(y)
            return sorted(found)
        side_u, side_v = side(u), side(v)
        smaller = side_u if len(side_u) < len(side_v) else side_v if len(side_v) < len(side_u) else (side_u if u < v else side_v)
        for x in smaller:
            component[x] = next_component
        next_component += 1
    return h if h < (1 << 63) else h - (1 << 64)
