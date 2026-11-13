"""Precision-doubling Newton inverse-square-root oracle."""

import struct

MODULUS = 998_244_353
MAX_INPUT_LENGTH = 66
MAX_OUTPUT_BYTES = 512
WORKSPACE_BYTES = 512
HALF = (MODULUS + 1) // 2


def multiply(left, right, width):
    result = [0] * width
    for i, a in enumerate(left[:width]):
        for j, b in enumerate(right[:width - i]):
            result[i + j] = (result[i + j] + a * b) % MODULUS
    return result


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
    inverse = [1]
    while len(inverse) < n:
        width = min(2 * len(inverse), n)
        product = multiply(f, multiply(inverse, inverse, width), width)
        correction = [(-x * HALF) % MODULUS for x in product]
        correction[0] = (3 - product[0]) * HALF % MODULUS
        inverse = multiply(inverse, correction, width)
    return 8 * n, b"".join(struct.pack("<q", x) for x in inverse)
