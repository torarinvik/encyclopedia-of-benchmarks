"""Independent edge-list verifier for the deterministic max-cut profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_NODES = 16
MAX_EDGES = 120
MAX_WEIGHT = 10_000
MAX_INPUT_LENGTH = 2 + 3 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * (MAX_NODES + 1)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 3 * m:
        return -1, b""
    edges = []
    seen = set()
    for pos in range(m):
        u, v, weight = values[2 + 3 * pos:5 + 3 * pos]
        if not 0 <= u < v < n or not 0 <= weight <= MAX_WEIGHT or (u, v) in seen:
            return -1, b""
        seen.add((u, v))
        edges.append((u, v, weight))
    partition = [-1] * n
    for vertex in range(n):
        zero_score = 0
        one_score = 0
        for u, v, weight in edges:
            if v == vertex:
                if partition[u] == 0:
                    one_score += weight
                else:
                    zero_score += weight
        partition[vertex] = 1 if one_score > zero_score else 0
    cut_value = 0
    for u, v, weight in edges:
        if partition[u] != partition[v]:
            cut_value += weight
    encoded_values = [cut_value, *partition]
    output = b"".join(struct.pack("<q", value) for value in encoded_values)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
