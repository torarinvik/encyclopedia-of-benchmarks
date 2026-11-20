"""Independent Kruskal reference for the seeded KKT minimum-spanning forest."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
MAX_VERTICES = 16
MAX_EDGES = 16
MAX_WEIGHT = 255
MAX_VALID_INPUT_LENGTH = 51
MAX_PARSEABLE_INPUT_LENGTH = 52


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or values is None or not isinstance(values, (tuple, list))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    n, m, seed = values[:3]
    if (not 1 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES
            or not 0 <= seed < (1 << 63)
            or len(values) != 3 + 3 * m or len(values) > MAX_VALID_INPUT_LENGTH):
        return INVALID_RESULT

    edges: list[tuple[int, int, int, int]] = []
    pairs: set[tuple[int, int]] = set()
    for edge_id in range(m):
        u, v, weight = values[3 + 3 * edge_id:6 + 3 * edge_id]
        if not 0 <= u < v < n or not 0 <= weight <= MAX_WEIGHT or (u, v) in pairs:
            return INVALID_RESULT
        pairs.add((u, v))
        edges.append((u, v, weight, edge_id))

    parent = list(range(n))

    def find(vertex: int) -> int:
        while parent[vertex] != vertex:
            parent[vertex] = parent[parent[vertex]]
            vertex = parent[vertex]
        return vertex

    result = 0
    for u, v, _, edge_id in sorted(edges, key=lambda edge: edge[2:]):
        root_u, root_v = find(u), find(v)
        if root_u != root_v:
            parent[root_v] = root_u
            result |= 1 << edge_id
    return result
