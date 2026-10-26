"""Independent machine-scan verifier for Graham list scheduling."""

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
    machine_count, job_count = values[0], values[1]
    durations = values[2:]
    if not 1 <= machine_count <= MAX_M or not 1 <= job_count <= MAX_N or len(durations) != job_count or any(t < 1 or t > 10000 for t in durations):
        return -1, b""
    load = [0] * machine_count
    machines_for_job = []
    for duration in durations:
        selected = 0
        for candidate in range(1, machine_count):
            if load[candidate] < load[selected]:
                selected = candidate
        machines_for_job.append(selected)
        load[selected] += duration
    answer = [max(load), *machines_for_job, *load]
    payload = b"".join(struct.pack("<q", value) for value in answer)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
