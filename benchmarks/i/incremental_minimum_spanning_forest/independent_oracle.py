"""Reference by rebuilding a Kruskal forest after each insertion."""

from __future__ import annotations

import struct
from collections.abc import Sequence


def expected_output(values: Sequence[int] | None, capacity: int = 256,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return -1, b""
    if any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values) or len(values) < 2:
        return -1, b""
    n, m = values[:2]
    if not 1 <= n <= 16 or not 1 <= m <= 32 or len(values) != 2 + 3 * m:
        return -1, b""
    edges = []
    seen = set()
    for i in range(m):
        u, v, weight = values[2 + 3 * i:5 + 3 * i]
        if not 0 <= u < n or not 0 <= v < n or not 1 <= weight <= 1_000_000 or weight in seen:
            return -1, b""
        seen.add(weight)
        edges.append((u, v, weight))
    previous: set[int] = set()
    answers = []
    for index in range(m):
        parent = list(range(n))

        def root(vertex: int) -> int:
            while parent[vertex] != vertex:
                vertex = parent[vertex]
            return vertex

        current = set()
        for edge in sorted(range(index + 1), key=lambda j: edges[j][2]):
            u, v, _ = edges[edge]
            a, b = root(u), root(v)
            if a != b:
                parent[b] = a
                current.add(edge)
        removed = (previous | {index}) - current
        answers.append(next(iter(removed)) if removed else -1)
        previous = current
    data = b"".join(struct.pack("<q", item) for item in answers)
    if output_is_null or capacity < len(data):
        return -2, b""
    return len(data), data
