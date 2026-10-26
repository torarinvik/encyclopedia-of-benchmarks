"""Independent verifier model for TSVC s2711's nonzero-B AXPY profile."""
from __future__ import annotations

import struct

MAX_N = 64
MAX_PASSES = 8
MAX_INPUT_LENGTH = 2 + 3 * MAX_N


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (not isinstance(values, (list, tuple)) or type(output_is_null) is not bool
            or type(input_is_null) is not bool
            or output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0 or input_length > MAX_INPUT_LENGTH)):
        return -1, b""
    if input_is_null or input_length is not None and input_length != len(values):
        return -1, b""
    if not 5 <= len(values) <= MAX_INPUT_LENGTH or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n, passes = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= passes <= MAX_PASSES or len(values) != 2 + 3 * n:
        return -1, b""
    if any(x < -2 or x > 2 for x in values[2:]):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < n * 8:
        return -2, b""
    a = values[2:2+n]
    b = values[2+n:2+2*n]
    c = values[2+2*n:]
    result = []
    for i in range(n):
        value = a[i]
        if b[i] != 0:
            value += passes * b[i] * c[i]
        result.append(value)
    return n, b"".join(struct.pack("<q", value) for value in result)
