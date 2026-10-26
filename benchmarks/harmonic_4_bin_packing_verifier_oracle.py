"""Independent HARM_4 bin-list verifier."""

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
    n, sizes = values[0], values[1:]
    if not 1 <= n <= MAX_N or len(sizes) != n or any(not 1 <= s <= CAPACITY for s in sizes):
        return -1, b""

    # Keep actual bin loads and class labels; choose the most recent bin of a class.
    loads: list[int] = []
    classes: list[int] = []
    assignment: list[int] = []
    for size in sizes:
        if size > CAPACITY // 2:
            kind = 0
        elif size * 3 > CAPACITY:
            kind = 1
        elif size * 4 > CAPACITY:
            kind = 2
        else:
            kind = 3
        candidate = -1
        for bin_id in range(len(loads) - 1, -1, -1):
            if classes[bin_id] == kind:
                candidate = bin_id
                break
        if candidate < 0 or loads[candidate] + size > CAPACITY:
            candidate = len(loads)
            loads.append(0)
            classes.append(kind)
        loads[candidate] += size
        assignment.append(candidate)
    output_values = [len(loads), *assignment]
    output = b"".join(struct.pack("<q", x) for x in output_values)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
