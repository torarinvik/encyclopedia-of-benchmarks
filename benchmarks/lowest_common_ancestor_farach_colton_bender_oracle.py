"""Direct parent-climb oracle for the bounded batched LCA contract."""

from __future__ import annotations

from collections.abc import Sequence

MAX_NODES = 256
MAX_QUERIES = 1024
MAX_INPUT_VALUES = 4 + 2 * (MAX_NODES - 1) + 2 * MAX_QUERIES


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (input_is_null or not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= MAX_INPUT_VALUES
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, root, edge_count, query_count = values[:4]
    if not 1 <= n <= MAX_NODES or not 0 <= root < n or edge_count != n - 1:
        return None
    if not 0 <= query_count <= MAX_QUERIES:
        return None
    query_offset = 4 + 2 * edge_count
    if len(values) != query_offset + 2 * query_count:
        return None
    adjacency = [[] for _ in range(n)]
    for edge in range(edge_count):
        u, v = values[4 + 2 * edge:6 + 2 * edge]
        if not (0 <= u < n and 0 <= v < n) or u == v:
            return None
        adjacency[u].append(v)
        adjacency[v].append(u)
    queries = []
    for query in range(query_count):
        u, v = values[query_offset + 2 * query:query_offset + 2 * query + 2]
        if not (0 <= u < n and 0 <= v < n):
            return None
        queries.append((u, v))
    parent = [-2] * n
    depth = [0] * n
    parent[root] = -1
    stack = [root]
    reached = 0
    while stack:
        node = stack.pop()
        reached += 1
        for neighbor in adjacency[node]:
            if neighbor == parent[node]:
                continue
            if parent[neighbor] != -2:
                return None
            parent[neighbor] = node
            depth[neighbor] = depth[node] + 1
            stack.append(neighbor)
    if reached != n:
        return None
    return parent, depth, queries


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    parent, depth, queries = parsed
    effective_capacity = MAX_QUERIES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if effective_capacity < len(queries) or (output_is_null and queries):
        return -2, b""
    answers = bytearray()
    for u, v in queries:
        while depth[u] > depth[v]:
            u = parent[u]
        while depth[v] > depth[u]:
            v = parent[v]
        while u != v:
            u = parent[u]
            v = parent[v]
        answers.append(u)
    return len(answers), bytes(answers)
