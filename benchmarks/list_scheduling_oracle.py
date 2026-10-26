"""Arrival-order, least-loaded-machine oracle for Graham list scheduling."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_M = 8
MAX_N = 32
MAX_INPUT = 34


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
    machines, jobs = values[:2]
    sizes = values[2:]
    if not 1 <= machines <= MAX_M or not 1 <= jobs <= MAX_N or len(sizes) != jobs or any(not 1 <= x <= 10000 for x in sizes):
        return -1, b""
    loads = [0] * machines
    assignment = []
    for size in sizes:
        machine = min(range(machines), key=lambda index: (loads[index], index))
        assignment.append(machine)
        loads[machine] += size
    values_out = [max(loads), *assignment, *loads]
    output = b"".join(struct.pack("<q", x) for x in values_out)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
