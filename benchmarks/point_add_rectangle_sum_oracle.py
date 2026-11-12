"""Direct point-scan oracle for bounded dynamic rectangle-sum traces."""

from __future__ import annotations

import struct

MAX_N = 32
MAX_Q = 32
MAX_COORD = 1_000_000
MAX_WEIGHT = 1_000_000
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_N + 5 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_Q


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)`` using a direct list scan for every rectangle."""
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
    if cursor + 3 * n > len(values):
        return -1, b""
    points = []
    for _ in range(n):
        x, y, weight = values[cursor:cursor + 3]
        cursor += 3
        if not (0 <= x <= MAX_COORD and 0 <= y <= MAX_COORD
                and 0 <= weight <= MAX_WEIGHT):
            return -1, b""
        points.append((x, y, weight))

    operations = []
    query_count = 0
    for _ in range(q):
        if cursor >= len(values):
            return -1, b""
        kind = values[cursor]
        cursor += 1
        if kind == 0:
            if cursor + 3 > len(values):
                return -1, b""
            x, y, weight = values[cursor:cursor + 3]
            cursor += 3
            if not (0 <= x <= MAX_COORD and 0 <= y <= MAX_COORD
                    and 0 <= weight <= MAX_WEIGHT):
                return -1, b""
            operations.append((0, x, y, weight))
        elif kind == 1:
            if cursor + 4 > len(values):
                return -1, b""
            left, down, right, up = values[cursor:cursor + 4]
            cursor += 4
            if not (0 <= left < right <= MAX_COORD
                    and 0 <= down < up <= MAX_COORD):
                return -1, b""
            operations.append((1, left, down, right, up))
            query_count += 1
        else:
            return -1, b""
    if cursor != len(values):
        return -1, b""

    answers = []
    for operation in operations:
        if operation[0] == 0:
            _, x, y, weight = operation
            points.append((x, y, weight))
        else:
            _, left, down, right, up = operation
            answers.append(sum(weight for x, y, weight in points
                               if left <= x < right and down <= y < up))

    required = 8 * query_count
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if required > 0 and (output_is_null or effective_capacity < required):
        return -2, b""
    output = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(output), output
