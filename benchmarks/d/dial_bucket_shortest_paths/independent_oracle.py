"""Structurally independent Floyd–Warshall oracle."""
from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_VERTICES = 16
MAX_EDGES = 64
MAX_EDGE_WEIGHT = 8
MAX_VALID_INPUT_LENGTH = 3 + 3 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_VERTICES


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, tuple[tuple[int, int, int], ...]] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, m, source = values[:3]
    if not 1 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES:
        return None
    if not 0 <= source < n or len(values) != 3 + 3 * m:
        return None
    edges = []
    for index in range(m):
        u, v, weight = values[3 + 3 * index: 6 + 3 * index]
        if not 0 <= u < n or not 0 <= v < n or not 0 <= weight <= MAX_EDGE_WEIGHT:
            return None
        edges.append((u, v, weight))
    return n, source, tuple(edges)


def _floyd(n: int, source: int, edges: Sequence[tuple[int, int, int]]) -> list[int]:
    infinity = 1 << 60
    distance = [[infinity] * n for _ in range(n)]
    for vertex in range(n):
        distance[vertex][vertex] = 0
    for u, v, weight in edges:
        if weight < distance[u][v]:
            distance[u][v] = weight
    for middle in range(n):
        for left in range(n):
            if distance[left][middle] == infinity:
                continue
            for right in range(n):
                candidate = distance[left][middle] + distance[middle][right]
                if candidate < distance[left][right]:
                    distance[left][right] = candidate
    return [-1 if value == infinity else value for value in distance[source]]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    n, source, edges = parsed
    required = 8 * n
    if output_is_null or capacity is not None and capacity < required:
        return -2, b""
    distances = _floyd(n, source, edges)
    return required, struct.pack("<" + "q" * n, *distances)

