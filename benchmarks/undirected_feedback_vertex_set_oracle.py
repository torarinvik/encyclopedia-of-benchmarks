"""Iterative-compression oracle for bounded undirected feedback vertex set."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 59


def _forest(edges: list[tuple[int, int]], vertices: int, n: int) -> bool:
    parent = list(range(n))

    def root(x: int) -> int:
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for u, v in edges:
        if vertices >> u & 1 and vertices >> v & 1:
            a, b = root(u), root(v)
            if a == b:
                return False
            parent[a] = b
    return True


def _budget_solution(edges: list[tuple[int, int]], n: int, budget: int) -> int | None:
    current = 0
    for end in range(1, n + 1):
        prefix = (1 << end) - 1
        candidate = current | (1 << (end - 1))
        if candidate.bit_count() <= budget:
            current = candidate
            continue
        found = None
        x = candidate
        while True:
            x_count = x.bit_count()
            if x_count <= budget and _forest(edges, candidate & ~x, n):
                eligible = prefix & ~candidate
                s = eligible
                while True:
                    if s.bit_count() <= budget - x_count and _forest(edges, prefix & ~(x | s), n):
                        found = x | s
                        break
                    if s == 0:
                        break
                    s = (s - 1) & eligible
                if found is not None:
                    break
            if x == 0:
                break
            x = (x - 1) & candidate
        if found is None:
            return None
        current = found
    return current


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
    minimum = None
    for budget in range(limit + 1):
        minimum = _budget_solution(edges, n, budget)
        if minimum is not None:
            break
    payload = struct.pack("<qq", int(minimum is not None), -1 if minimum is None else budget)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
