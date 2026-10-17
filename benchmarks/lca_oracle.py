"""Oracle for the bounded Java LCA tree/query contract."""
from __future__ import annotations
from collections.abc import Sequence

MAX_NODES = 64
MAX_INPUT_LENGTH = 2 * MAX_NODES + 1
INVALID_RESULT = -1


def expected_result(values: Sequence[int] | None, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    if type(input_is_null) is not bool or input_is_null or values is None:
        return INVALID_RESULT
    if not isinstance(values, (list, tuple)) or not values or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return INVALID_RESULT
    n = values[0]
    if not 1 <= n <= MAX_NODES or len(values) != 2 * n + 1:
        return INVALID_RESULT

    adjacency: list[list[int]] = [[] for _ in range(n)]
    dsu = list(range(n))

    def root(vertex: int) -> int:
        while dsu[vertex] != vertex:
            dsu[vertex] = dsu[dsu[vertex]]
            vertex = dsu[vertex]
        return vertex

    pos = 1
    for _ in range(n - 1):
        a, b = values[pos], values[pos + 1]
        pos += 2
        if not 0 <= a < n or not 0 <= b < n or a == b:
            return INVALID_RESULT
        root_a, root_b = root(a), root(b)
        if root_a == root_b:
            return INVALID_RESULT
        dsu[root_a] = root_b
        adjacency[a].append(b)
        adjacency[b].append(a)

    query_a, query_b = values[pos], values[pos + 1]
    if not 0 <= query_a < n or not 0 <= query_b < n:
        return INVALID_RESULT
    if any(root(vertex) != root(0) for vertex in range(n)):
        return INVALID_RESULT

    parent = [0] * n
    depth = [0] * n
    stack = [0]
    seen = [False] * n
    seen[0] = True
    while stack:
        vertex = stack.pop()
        for adjacent in adjacency[vertex]:
            if not seen[adjacent]:
                seen[adjacent] = True
                parent[adjacent] = vertex
                depth[adjacent] = depth[vertex] + 1
                stack.append(adjacent)

    a, b = query_a, query_b
    if depth[a] < depth[b]:
        a, b = b, a
    while depth[a] != depth[b]:
        a = parent[a]
    if a == b:
        return a
    while a != b:
        a, b = parent[a], parent[b]
    return a
