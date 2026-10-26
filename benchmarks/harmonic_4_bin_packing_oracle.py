"""HARM_4 classifier and independent class-local Next-Fit state oracle."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 32
MAX_INPUT = 33
CAPACITY = 10_000


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 2 or len(values) > MAX_INPUT or any(
            type(value) is not int or not -(1 << 63) <= value < (1 << 63)
            for value in values):
        return -1, b""
    n = values[0]
    sizes = values[1:]
    if not 1 <= n <= MAX_N or len(sizes) != n or any(not 1 <= x <= CAPACITY for x in sizes):
        return -1, b""

    # One current bin ID and remaining capacity per HARM_4 class.
    current = [-1] * 4
    remaining = [0] * 4
    assignment: list[int] = []
    bins = 0
    for size in sizes:
        if size * 2 > CAPACITY:
            kind = 0
        elif size * 3 > CAPACITY:
            kind = 1
        elif size * 4 > CAPACITY:
            kind = 2
        else:
            kind = 3
        if current[kind] < 0 or size > remaining[kind]:
            current[kind] = bins
            bins += 1
            remaining[kind] = CAPACITY
        assignment.append(current[kind])
        remaining[kind] -= size
    output = b"".join(struct.pack("<q", x) for x in (bins, *assignment))
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
