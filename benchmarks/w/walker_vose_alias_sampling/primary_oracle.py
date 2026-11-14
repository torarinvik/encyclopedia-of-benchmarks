"""Bounded integer Walker–Vose alias-table reference."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 83
MAX_OUTPUT_BYTES = 256


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(input_is_null) is not bool or type(output_is_null) is not bool
            or input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 3 or len(values) > MAX_INPUT_LENGTH
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1, b""
    n, q = values[:2]
    if not 1 <= n <= 16 or not 0 <= q <= 32 or len(values) != 2 + n + 2 * q:
        return -1, b""
    weights = values[2:2 + n]
    if any(w < 0 or w > 100 for w in weights):
        return -1, b""
    total = sum(weights)
    if total == 0:
        return -1, b""
    draws = values[2 + n:]
    if any(not 0 <= draws[i] < n or not 0 <= draws[i + 1] < total
           for i in range(0, len(draws), 2)):
        return -1, b""
    if q == 0:
        return 0, b""
    if output_is_null or capacity is not None and capacity < 8 * q:
        return -2, b""
    mass = [n * w for w in weights]
    small = [i for i in range(n) if mass[i] < total]
    large = [i for i in range(n) if mass[i] >= total]
    threshold = [total] * n
    alias = list(range(n))
    while small and large:
        low, high = small.pop(), large.pop()
        threshold[low], alias[low] = mass[low], high
        mass[high] -= total - mass[low]
        (small if mass[high] < total else large).append(high)
    selected = [column if ticket < threshold[column] else alias[column]
                for column, ticket in zip(draws[::2], draws[1::2])]
    return 8 * q, struct.pack("<" + "q" * q, *selected)
