"""Direct mutable-array oracle for range affine point-get traces."""

from __future__ import annotations

import struct

MOD = 998244353
MAX_N = 256
MAX_Q = 256
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + 5 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_Q


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Validate and answer by mutating every array element in each update."""
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
    array = list(values[cursor:cursor + n])
    cursor += n
    if any(not 0 <= value < MOD for value in array):
        return -1, b""

    operations = []
    query_count = 0
    for _ in range(q):
        if cursor >= len(values):
            return -1, b""
        kind = values[cursor]
        cursor += 1
        if kind == 0:
            if cursor + 4 > len(values):
                return -1, b""
            left, right, multiplier, offset = values[cursor:cursor + 4]
            cursor += 4
            if (not 0 <= left < right <= n or not 1 <= multiplier < MOD
                    or not 0 <= offset < MOD):
                return -1, b""
            operations.append((0, left, right, multiplier, offset))
        elif kind == 1:
            if cursor >= len(values):
                return -1, b""
            index = values[cursor]
            cursor += 1
            if not 0 <= index < n:
                return -1, b""
            operations.append((1, index))
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
            _, left, right, multiplier, offset = operation
            for index in range(left, right):
                array[index] = (multiplier * array[index] + offset) % MOD
        else:
            answers.append(array[operation[1]])
    output = b"".join(struct.pack("<q", value) for value in answers)
    return len(output), output
