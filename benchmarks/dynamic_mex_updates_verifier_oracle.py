"""Independent direct-scan oracle for dynamic MEX update traces."""

from __future__ import annotations

import struct

MAX_N = 32
MAX_Q = 32
MIN_VALUE = -1000
MAX_VALUE = 1000
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + 2 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_Q


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 2
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)):
        return -1, b""
    if any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63)
           for value in values):
        return -1, b""
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q:
        return -1, b""
    if len(values) != 2 + n + 2 * q:
        return -1, b""
    current = list(values[2:2 + n])
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in current):
        return -1, b""
    operations = []
    cursor = 2 + n
    for _ in range(q):
        index, replacement = values[cursor], values[cursor + 1]
        cursor += 2
        if not 0 <= index < n or not MIN_VALUE <= replacement <= MAX_VALUE:
            return -1, b""
        operations.append((index, replacement))

    required = 8 * q
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if required > 0 and (output_is_null or effective_capacity < required):
        return -2, b""

    answers = []
    for index, replacement in operations:
        current[index] = replacement
        occupied = set(value for value in current if 0 <= value <= n)
        candidate = 0
        while candidate in occupied:
            candidate += 1
        answers.append(candidate)
    output = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(output), output


def expected_result(values, **kwargs):
    return expected_output(values, **kwargs)[0]
