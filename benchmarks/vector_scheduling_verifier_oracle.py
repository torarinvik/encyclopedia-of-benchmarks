"""Independent verifier recomputing per-machine coordinate sums by job scan."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 83


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
    if len(values) < 3 or len(values) > MAX_INPUT or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values):
        return -1, b""
    n, machine_count, dimension_count = values[:3]
    if not 1 <= n <= 16 or not 1 <= machine_count <= 8 or not 1 <= dimension_count <= 4 or len(values) != 3+n+n*dimension_count:
        return -1, b""
    assignment = tuple(values[3:3+n])
    components = tuple(values[3+n:])
    if any(machine < 0 or machine >= machine_count for machine in assignment) or any(x < 0 or x > 1000 for x in components):
        return -1, b""
    total = [0] * (machine_count * dimension_count)
    for job in range(n):
        start = job * dimension_count
        machine_base = assignment[job] * dimension_count
        for dimension in range(dimension_count):
            total[machine_base + dimension] = total[machine_base + dimension] + components[start + dimension]
    span = 0
    for amount in total:
        if amount > span:
            span = amount
    fields = (machine_count, dimension_count, span, *total)
    payload = b"".join(struct.pack("<q", value) for value in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
