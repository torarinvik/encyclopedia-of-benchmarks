"""Scalar GF(2) oracle for bounded binary matrix multiplication."""

import struct

MAX_DIMENSION = 64
MAX_PARSEABLE_INPUT_LENGTH = 3 + 2 * MAX_DIMENSION * MAX_DIMENSION
MAX_OUTPUT_BYTES = 8 * MAX_DIMENSION * MAX_DIMENSION


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)`` for ``[N,M,K,A...,B...]``."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or input_length < 3 or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return -1, b""

    rows, shared, columns = values[:3]
    if not all(1 <= dimension <= MAX_DIMENSION
               for dimension in (rows, shared, columns)):
        return -1, b""
    a_length = rows * shared
    b_length = shared * columns
    if len(values) != 3 + a_length + b_length:
        return -1, b""
    a = values[3:3 + a_length]
    b = values[3 + a_length:]
    if any(value not in (0, 1) for value in (*a, *b)):
        return -1, b""

    result_values = []
    for row in range(rows):
        for column in range(columns):
            bit = 0
            for inner in range(shared):
                bit ^= a[row * shared + inner] & b[inner * columns + column]
            result_values.append(bit)

    required = 8 * len(result_values)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < required:
        return -2, b""
    return required, b"".join(struct.pack("<q", value) for value in result_values)
