"""Coefficient recurrence derived from 2 f g' + f' g = 0."""

import struct

MODULUS = 998_244_353
MAX_INPUT_LENGTH = 66
MAX_OUTPUT_BYTES = 512


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or type(output_is_null) is not bool
            or input_is_null or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1, b""
    n = values[0]
    if (not 1 <= n <= 64 or len(values) != n + 1 or values[1] != 1
            or any(not 0 <= x < MODULUS for x in values[1:])):
        return -1, b""
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < 8 * n)):
        return -2, b""
    f = values[1:]
    result = [1] + [0] * (n - 1)
    for degree in range(1, n):
        total = sum((2 * degree - i) * f[i] * result[degree - i]
                    for i in range(1, degree + 1))
        result[degree] = -total * pow(2 * degree, MODULUS - 2, MODULUS) % MODULUS
    return 8 * n, b"".join(struct.pack("<q", x) for x in result)
