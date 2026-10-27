"""Independent direct suffix-order verifier for suffix-tree occurrence queries."""
from __future__ import annotations

import struct
from collections.abc import Sequence


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 3 or len(values) > 39 or any(
            type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n = values[0]
    if not 0 <= n <= 24 or len(values) < 2 + n:
        return -1, b""
    m = values[1 + n]
    if not 1 <= m <= 12 or len(values) != 2 + n + m:
        return -1, b""
    text = values[1:1 + n]
    pattern = values[2 + n:]
    if any(not 0 <= ch <= 127 for ch in (*text, *pattern)):
        return -1, b""
    positions = [i for i in range(n - m + 1) if tuple(text[i:i + m]) == tuple(pattern)] if m <= n else []
    # Lexicographic suffix order, using the unique terminal symbol -1.
    positions.sort(key=lambda i: tuple(text[i:]) + (-1,))
    payload = struct.pack("<" + "q" * (1 + len(positions)), len(positions), *positions)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
