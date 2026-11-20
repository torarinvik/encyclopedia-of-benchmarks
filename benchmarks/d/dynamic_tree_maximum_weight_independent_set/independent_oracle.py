"""Independent tree-DP replay oracle for dynamic tree MWIS."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 64
MAX_UPDATES = 64
MAX_WEIGHT = 1_000_000
MAX_OUTPUT_BYTES = 8 * MAX_UPDATES


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool):
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    actual = len(values) if input_length is None else input_length
    if type(actual) is not int or actual != len(values) or actual < 2:
        return None
    if any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return None
    n, q = values[:2]
    if not 1 <= n <= MAX_VERTICES or not 0 <= q <= MAX_UPDATES:
        return None
    edge_end = 2 + n + 2 * (n - 1)
    if actual != edge_end + 2 * q:
        return None
    weights = list(values[2:2 + n])
    if any(not 0 <= w <= MAX_WEIGHT for w in weights):
        return None
    edges = []
    parent = list(range(n))

    def find(x: int) -> int:
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for edge in range(n - 1):
        u, v = values[2 + n + 2 * edge: 4 + n + 2 * edge]
        if not 0 <= u < n or not 0 <= v < n or u == v:
            return None
        ru, rv = find(u), find(v)
        if ru == rv:
            return None
        parent[ru] = rv
        edges.append((u, v))
    if any(find(v) != find(0) for v in range(n)):
        return None
    updates = []
    for i in range(q):
        vertex, weight = values[edge_end + 2 * i:edge_end + 2 * i + 2]
        if not 0 <= vertex < n or not 0 <= weight <= MAX_WEIGHT:
            return None
        updates.append((vertex, weight))
    return n, weights, edges, updates


def _replay(n: int, weights: list[int], edges: list[tuple[int, int]], updates: list[tuple[int, int]]):
    neighbors = [[] for _ in range(n)]
    for u, v in edges:
        neighbors[u].append(v)
        neighbors[v].append(u)
    parent = [-2] * n
    parent[0] = -1
    order = [0]
    for u in order:
        for v in neighbors[u]:
            if parent[v] == -2:
                parent[v] = u
                order.append(v)
    answers = []
    for vertex, value in updates:
        weights[vertex] = value
        skip = [0] * n
        take = [0] * n
        for u in reversed(order):
            skip[u] = 0
            take[u] = weights[u]
            for v in neighbors[u]:
                if parent[v] == u:
                    skip[u] += max(skip[v], take[v])
                    take[u] += skip[v]
        answers.append(max(skip[0], take[0]))
    return answers


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _decode(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    n, weights, edges, updates = parsed
    required = 8 * len(updates)
    if type(output_is_null) is not bool:
        return -2, b""
    if output_capacity is None:
        capacity = MAX_OUTPUT_BYTES
    elif type(output_capacity) is not int or output_capacity < 0:
        return -2, b""
    else:
        capacity = output_capacity
    if required and (output_is_null or capacity < required):
        return -2, b""
    answers = _replay(n, weights, edges, updates)
    return required, b"".join(value.to_bytes(8, "little", signed=True) for value in answers)
