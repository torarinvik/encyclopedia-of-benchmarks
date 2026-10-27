"""DSU oracle for one supplied-randomness graph-contraction phase."""

from __future__ import annotations

import struct
from collections import deque
from collections.abc import Sequence

MAX_N = 16
MAX_M = 24
MAX_INPUT = 74
MAX_OUTPUT_BYTES = 64


def _parse(values: Sequence[int]) -> tuple[int, list[tuple[int, int, int]]] | None:
    if len(values) < 5 or len(values) > MAX_INPUT or any(
            type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, m = values[:2]
    if not 2 <= n <= MAX_N or not n - 1 <= m <= MAX_M or len(values) != 2 + 3*m:
        return None
    edges: list[tuple[int, int, int]] = []
    pairs: set[tuple[int, int]] = set()
    for index in range(m):
        u, v, contract = values[2 + 3*index:5 + 3*index]
        if not 0 <= u < v < n or contract not in (0, 1) or (u, v) in pairs:
            return None
        pairs.add((u, v))
        edges.append((u, v, contract))
    seen = {0}
    queue = deque([0])
    while queue:
        current = queue.popleft()
        for u, v, _ in edges:
            neighbor = v if u == current else u if v == current else -1
            if neighbor >= 0 and neighbor not in seen:
                seen.add(neighbor)
                queue.append(neighbor)
    if len(seen) != n:
        return None
    return n, edges


def _contract(n: int, edges: list[tuple[int, int, int]]) -> bytes:
    parent = list(range(n))

    def find(vertex: int) -> int:
        while parent[vertex] != vertex:
            parent[vertex] = parent[parent[vertex]]
            vertex = parent[vertex]
        return vertex

    for u, v, bit in edges:
        if bit:
            left, right = find(u), find(v)
            if left != right:
                parent[right] = left
    minima = [n] * n
    for vertex in range(n):
        root = find(vertex)
        minima[root] = min(minima[root], vertex)
    return b"".join(struct.pack("<i", minima[find(vertex)]) for vertex in range(n))


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
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    payload = _contract(*parsed)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
