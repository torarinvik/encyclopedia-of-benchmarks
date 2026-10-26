"""Branch-and-search oracle for the bounded vertex-cover search-tree profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 131


def _solve(adj: list[set[int]], active: int, n: int) -> int:
    chosen = -1
    best_degree = 0
    for u in range(n):
        if active >> u & 1:
            degree = sum(bool(active >> v & 1) for v in adj[u])
            if degree > 0 and (chosen < 0 or degree > best_degree):
                chosen, best_degree = u, degree
    if chosen < 0:
        return 0
    bit = 1 << chosen
    include = bit | _solve(adj, active & ~bit, n)
    neighbors = sum(1 << v for v in adj[chosen] if active >> v & 1)
    exclude = neighbors | _solve(adj, active & ~(neighbors | bit), n)
    left = (include.bit_count(), include)
    right = (exclude.bit_count(), exclude)
    return include if left <= right else exclude


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
    n, m, parameter = values[:3]
    if not 1 <= n <= 16 or not 0 <= m <= 64 or not 0 <= parameter <= n or len(values) != 3 + 2*m:
        return -1, b""
    adjacency = [set() for _ in range(n)]
    previous = (-1, -1)
    for index in range(m):
        u, v = values[3+2*index:5+2*index]
        if not 0 <= u < v < n or (u, v) <= previous:
            return -1, b""
        adjacency[u].add(v)
        adjacency[v].add(u)
        previous = (u, v)
    cover = _solve(adjacency, (1 << n) - 1, n)
    size = cover.bit_count()
    payload = struct.pack("<qqq", int(size <= parameter), size, cover)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
