"""Reference oracle for the deterministic Sahni-Gonzalez max-cut profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_NODES = 16
MAX_EDGES = 120
MAX_WEIGHT = 10_000
MAX_INPUT_LENGTH = 2 + 3 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * (MAX_NODES + 1)


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 3 * m:
        return None
    edges = []
    seen = set()
    for offset in range(2, len(values), 3):
        u, v, weight = values[offset:offset + 3]
        if not 0 <= u < v < n or not 0 <= weight <= MAX_WEIGHT or (u, v) in seen:
            return None
        seen.add((u, v))
        edges.append((u, v, weight))
    return n, edges


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
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, edges = parsed
    side = [0] * n
    for vertex in range(n):
        if vertex == 0:
            continue
        put_zero = sum(weight for u, v, weight in edges
                       if v == vertex and side[u] == 1)
        put_one = sum(weight for u, v, weight in edges
                      if v == vertex and side[u] == 0)
        side[vertex] = 1 if put_one > put_zero else 0
    cut = sum(weight for u, v, weight in edges if side[u] != side[v])
    payload = [cut, *side]
    output = b"".join(struct.pack("<q", value) for value in payload)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
