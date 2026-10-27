"""Independent exhaustive-subset verifier for bounded weighted set cover."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_ROWS = 8
MAX_COLUMNS = 10
MAX_INPUT_LENGTH = 21


def _decode(values: Sequence[int] | None):
    if not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63) for value in values):
        return None
    m, n = values[:2]
    if not 1 <= m <= MAX_ROWS or not 1 <= n <= MAX_COLUMNS:
        return None
    if len(values) != 2 + m + n:
        return None
    weights = list(values[2:2 + n])
    rows = list(values[2 + n:])
    if any(weight < 1 or weight > 20 for weight in weights):
        return None
    allowed = (1 << n) - 1
    if any(row < 0 or row & ~allowed for row in rows):
        return None
    return m, n, weights, rows


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    m, n, weights, rows = decoded
    best = None
    for mask in range(1 << n):
        if not all(mask & row for row in rows):
            continue
        cost = sum(weights[column] for column in range(n) if mask & (1 << column))
        key = (cost, mask)
        if best is None or key < best:
            best = key
    if best is None:
        payload = struct.pack("<q", -1)
    else:
        cost, mask = best
        selected = [column for column in range(n) if mask & (1 << column)]
        payload = struct.pack("<" + "q" * (len(selected) + 2), len(selected), *selected, cost)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
