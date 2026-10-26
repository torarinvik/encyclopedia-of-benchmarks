"""Exact output oracle for the bounded generalized First Fit profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 130
MAX_OUTPUT = 8 * 161


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
    if len(values) < 2 or len(values) > MAX_INPUT or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n, dimensions = values[:2]
    if not 1 <= n <= 32 or not 1 <= dimensions <= 4 or len(values) != 2 + n * dimensions:
        return -1, b""
    vectors = [values[2 + i * dimensions:2 + (i + 1) * dimensions] for i in range(n)]
    if any(not 0 <= coordinate <= 1000 for vector in vectors for coordinate in vector):
        return -1, b""

    bins: list[list[int]] = []
    assignment: list[int] = []
    for vector in vectors:
        destination = 0
        while destination < len(bins):
            if all(bins[destination][axis] + vector[axis] <= 1000 for axis in range(dimensions)):
                break
            destination += 1
        if destination == len(bins):
            bins.append([0] * dimensions)
        assignment.append(destination)
        for axis, coordinate in enumerate(vector):
            bins[destination][axis] += coordinate

    fields = [len(bins), *assignment]
    fields.extend(load for bin_load in bins for load in bin_load)
    payload = b"".join(struct.pack("<q", field) for field in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
