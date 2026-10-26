"""Exact expected-output oracle for supplied-choice vector scheduling."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 83
MAX_OUTPUT = 280


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
    n, machines, dimensions = values[:3]
    if not 1 <= n <= 16 or not 1 <= machines <= 8 or not 1 <= dimensions <= 4 or len(values) != 3+n+n*dimensions:
        return -1, b""
    choices = values[3:3+n]
    job_vectors = [values[3+n+j*dimensions:3+n+(j+1)*dimensions] for j in range(n)]
    if any(not 0 <= machine < machines for machine in choices) or any(not 0 <= x <= 1000 for row in job_vectors for x in row):
        return -1, b""
    loads = [[0] * dimensions for _ in range(machines)]
    for machine, vector in zip(choices, job_vectors):
        for dimension, amount in enumerate(vector):
            loads[machine][dimension] += amount
    makespan = max(amount for row in loads for amount in row)
    fields = [machines, dimensions, makespan]
    fields.extend(amount for row in loads for amount in row)
    payload = b"".join(struct.pack("<q", field) for field in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
