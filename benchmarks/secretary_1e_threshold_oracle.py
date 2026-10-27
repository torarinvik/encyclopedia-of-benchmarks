"""Exact finite-profile oracle for the classic 1/e secretary threshold rule."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 16
MAX_INPUT = 17
MAX_OUTPUT_BYTES = 8
SAMPLE_COUNTS = (0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 4, 4, 4, 5, 5, 5)


def _select(values: Sequence[int]) -> int | None:
    if (not 4 <= len(values) <= MAX_INPUT or any(
            type(value) is not int or not -(1 << 63) <= value < (1 << 63)
            for value in values)):
        return None
    n = values[0]
    if not 3 <= n <= MAX_N or len(values) != n + 1:
        return None
    ranks = list(values[1:])
    if sorted(ranks) != list(range(1, n + 1)):
        return None
    sample_count = SAMPLE_COUNTS[n]
    sample_max = max(ranks[:sample_count])
    for index in range(sample_count, n):
        if ranks[index] > sample_max:
            return index
    return -1


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    selected = _select(values)
    if selected is None:
        return -1, b""
    payload = struct.pack("<q", selected)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
