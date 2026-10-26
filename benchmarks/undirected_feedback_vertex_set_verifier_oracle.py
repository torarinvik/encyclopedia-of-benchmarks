"""Independent verifier by enumerating all vertex subsets in size order."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 59


def _is_acyclic(n: int, edges: list[tuple[int, int]], removed: int) -> bool:
    parent = list(range(n))

    def find(vertex: int) -> int:
        while parent[vertex] != vertex:
            parent[vertex] = parent[parent[vertex]]
            vertex = parent[vertex]
        return vertex

    for u, v in edges:
        if removed >> u & 1 or removed >> v & 1:
            continue
        left, right = find(u), find(v)
        if left == right:
            return False
        parent[left] = right
    return True


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 3 or len(values) > MAX_INPUT or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n, m, limit = values[:3]
    if not 1 <= n <= 8 or not 0 <= m <= 28 or not 0 <= limit <= 4 or len(values) != 3 + 2*m:
        return -1, b""
    edges = []
    previous = (-1, -1)
    for i in range(m):
        u, v = values[3+2*i:5+2*i]
        if not 0 <= u < v < n or (u, v) <= previous:
            return -1, b""
        edges.append((u, v))
        previous = (u, v)
    minimum = next((size for size in range(limit + 1)
                    if any(mask.bit_count() == size and _is_acyclic(n, edges, mask)
                           for mask in range(1 << n))), None)
    payload = struct.pack("<qq", int(minimum is not None), -1 if minimum is None else minimum)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
