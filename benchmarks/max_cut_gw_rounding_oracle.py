"""Bounded supplied-hyperplane Goemans--Williamson Max-Cut rounding profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 16
MAX_M = 120
MAX_D = 4
MAX_INPUT_LENGTH = 431
MAX_OUTPUT_BYTES = 8 * (MAX_N + 1)


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 3
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m, d = values[:3]
    if not 2 <= n <= MAX_N or not 0 <= m <= MAX_M or not 1 <= d <= MAX_D:
        return None
    if len(values) != 3 + 3 * m + n * d + d:
        return None
    edges = []
    prior = (-1, -1)
    for edge in range(m):
        u, v, weight = values[3 + 3 * edge:6 + 3 * edge]
        if not (0 <= u < v < n and 1 <= weight <= 10000 and (u, v) > prior):
            return None
        prior = (u, v)
        edges.append((u, v, weight))
    offset = 3 + 3 * m
    vectors = [list(values[offset + vertex * d:offset + (vertex + 1) * d])
               for vertex in range(n)]
    if any(abs(value) > 100 for vector in vectors for value in vector):
        return None
    norm = sum(value * value for value in vectors[0])
    if norm == 0 or any(sum(value * value for value in vector) != norm
                        for vector in vectors[1:]):
        return None
    hyperplane = list(values[offset + n * d:])
    if (any(abs(value) > 100 for value in hyperplane)
            or not any(hyperplane)):
        return None
    return n, edges, d, vectors, hyperplane


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and isinstance(values, (list, tuple)) and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, edges, d, vectors, hyperplane = parsed
    output_bytes = 8 * (n + 1)
    if output_is_null or capacity is not None and capacity < output_bytes:
        return -2, b""
    side = [1 if sum(vectors[vertex][axis] * hyperplane[axis]
                     for axis in range(d)) > 0 else 0 for vertex in range(n)]
    cut = sum(weight for u, v, weight in edges if side[u] != side[v])
    return output_bytes, b"".join(struct.pack("<q", value) for value in (cut, *side))
