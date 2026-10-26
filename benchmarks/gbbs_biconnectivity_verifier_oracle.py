"""Independent vertex-separator verifier for undirected biconnected edge blocks."""

from __future__ import annotations

import struct

MAX_NODES = 12
MAX_EDGES = 24
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(item) is not int or not I64_MIN <= item <= I64_MAX for item in values)):
        return -1, b""
    n, m = values[:2]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return -1, b""
    edges = []
    adjacent = [[False] * n for _ in range(n)]
    for pos in range(2, len(values), 2):
        u, v = values[pos:pos + 2]
        if not 0 <= u < v < n or adjacent[u][v]:
            return -1, b""
        adjacent[u][v] = adjacent[v][u] = True
        edges.append((u, v))

    # First identify original connected components. A pair of edges in
    # different components can never belong to the same block.
    original_component = [-1] * n
    for root in range(n):
        if original_component[root] != -1:
            continue
        original_component[root] = root
        todo = [root]
        for vertex in todo:
            for other in range(n):
                if adjacent[vertex][other] and original_component[other] == -1:
                    original_component[other] = root
                    todo.append(other)

    # For every possible deleted vertex, compute the remaining components.
    # Edges in different remaining components are in different vertex blocks.
    sides = []
    for removed in range(n):
        labels = [-1] * n
        for root in range(n):
            if root == removed or labels[root] != -1:
                continue
            labels[root] = root
            todo = [root]
            for vertex in todo:
                for other in range(n):
                    if (other != removed and adjacent[vertex][other]
                            and labels[other] == -1):
                        labels[other] = root
                        todo.append(other)
        edge_sides = []
        for u, v in edges:
            endpoint = v if u == removed else u if v == removed else u
            edge_sides.append(labels[endpoint])
        sides.append(edge_sides)

    parent = list(range(m))

    def find(edge: int) -> int:
        while parent[edge] != edge:
            parent[edge] = parent[parent[edge]]
            edge = parent[edge]
        return edge

    for left in range(m):
        for right in range(left + 1, m):
            if original_component[edges[left][0]] != original_component[edges[right][0]]:
                continue
            if all(sides[removed][left] == sides[removed][right] for removed in range(n)):
                a, b = find(left), find(right)
                if a != b:
                    parent[b] = a

    group_min: dict[int, int] = {}
    for edge in range(m):
        root = find(edge)
        group_min[root] = min(group_min.get(root, m), edge)
    output = bytes(group_min[find(edge)] for edge in range(m))
    if output_is_null or capacity is not None and capacity < m:
        return -2, b""
    return m, output
