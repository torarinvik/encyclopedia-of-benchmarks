"""Independent reference for supplied-hyperplane Goemans--Williamson rounding."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 431
MAX_OUTPUT_BYTES = 136


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
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if (len(values) < 3 or len(values) > MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1, b""
    n, m, d = values[0], values[1], values[2]
    if not 2 <= n <= 16 or not 0 <= m <= 120 or not 1 <= d <= 4:
        return -1, b""
    edge_end = 3 + 3 * m
    if len(values) != edge_end + n * d + d:
        return -1, b""
    edges = []
    previous = None
    for start in range(3, edge_end, 3):
        u, v, weight = values[start:start + 3]
        pair = (u, v)
        if (u < 0 or v <= u or v >= n or not 1 <= weight <= 10000
                or previous is not None and pair <= previous):
            return -1, b""
        previous = pair
        edges.append((u, v, weight))
    vector_start = edge_end
    vectors = [values[vector_start + i * d:vector_start + (i + 1) * d]
               for i in range(n)]
    if any(abs(c) > 100 for vector in vectors for c in vector):
        return -1, b""
    lengths_squared = [sum(c * c for c in vector) for vector in vectors]
    normal = values[vector_start + n * d:]
    if (not lengths_squared[0] or any(s != lengths_squared[0] for s in lengths_squared)
            or any(abs(c) > 100 for c in normal) or not any(normal)):
        return -1, b""
    result_bytes = 8 * (n + 1)
    if output_is_null or capacity is not None and capacity < result_bytes:
        return -2, b""
    labels = []
    for vector in vectors:
        projection = 0
        for coordinate, normal_coordinate in zip(vector, normal):
            projection += coordinate * normal_coordinate
        labels.append(0 if projection <= 0 else 1)
    crossing = 0
    for u, v, weight in edges:
        if labels[u] != labels[v]:
            crossing += weight
    raw = struct.pack("<q", crossing)
    raw += b"".join(struct.pack("<q", label) for label in labels)
    return result_bytes, raw
