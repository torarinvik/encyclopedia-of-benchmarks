"""Direct-array oracle for point-set/range-frequency traces."""

from __future__ import annotations

import struct

MAX_N = 64
MAX_Q = 64
MAX_VALUE = 1_000_000
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + 4 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_Q


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Validate input and count by scanning the current array for every query."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 0
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values) or len(values) < 2):
        return -1, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return -1, b""

    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q:
        return -1, b""
    cursor = 2
    if cursor + n > len(values):
        return -1, b""
    current = list(values[cursor:cursor + n])
    cursor += n
    if any(not 0 <= value <= MAX_VALUE for value in current):
        return -1, b""

    operations = []
    query_count = 0
    for _ in range(q):
        if cursor >= len(values):
            return -1, b""
        kind = values[cursor]
        cursor += 1
        if kind == 0:
            if cursor + 2 > len(values):
                return -1, b""
            index, value = values[cursor:cursor + 2]
            cursor += 2
            if not 0 <= index < n or not 0 <= value <= MAX_VALUE:
                return -1, b""
            operations.append((0, index, value))
        elif kind == 1:
            if cursor + 3 > len(values):
                return -1, b""
            left, right, value = values[cursor:cursor + 3]
            cursor += 3
            if not 0 <= left <= right <= n or not 0 <= value <= MAX_VALUE:
                return -1, b""
            operations.append((1, left, right, value))
            query_count += 1
        else:
            return -1, b""
    if cursor != len(values):
        return -1, b""

    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    required = 8 * query_count
    if required > 0 and (output_is_null or effective_capacity < required):
        return -2, b""

    answers = []
    for operation in operations:
        if operation[0] == 0:
            _, index, value = operation
            current[index] = value
        else:
            _, left, right, value = operation
            answers.append(sum(item == value for item in current[left:right]))
    output = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(output), output
