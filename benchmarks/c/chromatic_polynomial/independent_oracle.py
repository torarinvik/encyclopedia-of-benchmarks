"""Independent spanning-subgraph inclusion-exclusion verifier."""

from __future__ import annotations

import struct

MAX_VERTICES = 8
MAX_EDGES = 16
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * (MAX_VERTICES + 1)


def expected_output(values: list[int] | tuple[int, ...] | None,
                    capacity: int | None = None, output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n, m = values[:2]
    if not 0 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return -1, b""
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for offset in range(2, len(values), 2):
        u, v = values[offset:offset + 2]
        if not 0 <= u < n or not 0 <= v < n or u == v:
            return -1, b""
        edge = (min(u, v), max(u, v))
        if edge in seen:
            return -1, b""
        seen.add(edge)
        edges.append(edge)

    coefficients = [0] * (n + 1)
    for subset in range(1 << m):
        parent = list(range(n))

        def find(vertex: int) -> int:
            while parent[vertex] != vertex:
                parent[vertex] = parent[parent[vertex]]
                vertex = parent[vertex]
            return vertex

        for edge_index, (u, v) in enumerate(edges):
            if (subset >> edge_index) & 1:
                root_u = find(u)
                root_v = find(v)
                if root_u != root_v:
                    parent[root_u] = root_v
        components = len({find(vertex) for vertex in range(n)})
        coefficients[components] += -1 if subset.bit_count() & 1 else 1
    payload = b"".join(struct.pack("<q", coefficient) for coefficient in coefficients)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0 or output_is_null or effective_capacity < len(payload)):
        return -2, b""
    return len(payload), payload
