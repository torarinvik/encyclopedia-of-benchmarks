"""Independent verifier by exhaustive vertex-subset enumeration."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 131


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
    if not 1 <= n <= 16 or not 0 <= m <= 64 or not 0 <= parameter <= n or len(values) != 3+2*m:
        return -1, b""
    edges = []
    previous = (-1, -1)
    for j in range(m):
        edge = (values[3+2*j], values[4+2*j])
        if not 0 <= edge[0] < edge[1] < n or edge <= previous:
            return -1, b""
        edges.append(edge)
        previous = edge
    selected = None
    for size in range(n+1):
        for mask in range(1 << n):
            if mask.bit_count() != size:
                continue
            if all((mask >> u & 1) or (mask >> v & 1) for u, v in edges):
                selected = mask
                break
        if selected is not None:
            break
    assert selected is not None
    size = selected.bit_count()
    payload = struct.pack("<qqq", int(size <= parameter), size, selected)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
