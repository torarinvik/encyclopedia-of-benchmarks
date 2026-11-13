"""Precision-doubling Newton reversion in a bounded prime field."""

import struct

MODULUS = 998_244_353
MAX_INPUT_LENGTH = 18
MAX_OUTPUT_BYTES = 128
WORKSPACE_BYTES = 2176


def _multiply(left, right, width):
    result = [0] * width
    for i, a in enumerate(left[:width]):
        for j, b in enumerate(right[:width - i]):
            result[i + j] = (result[i + j] + a * b) % MODULUS
    return result


def _compose(outer, inner, width):
    result = [0] * width
    for coefficient in reversed(outer[:width]):
        result = _multiply(result, inner, width)
        result[0] = (result[0] + coefficient) % MODULUS
    return result


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or type(output_is_null) is not bool
            or input_is_null or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n = values[0]
    if (not 2 <= n <= 16 or len(values) != n + 1
            or any(not 0 <= value < MODULUS for value in values[1:])
            or values[1] != 0 or values[2] == 0):
        return -1, b""
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < 8 * n)):
        return -2, b""
    f = list(values[1:])
    derivative = [i * f[i] % MODULUS for i in range(1, n)]
    inverse_linear = pow(f[1], MODULUS - 2, MODULUS)
    inverse = [0] * n
    inverse[1] = inverse_linear
    precision = 2
    while precision < n:
        width = min(2 * precision, n)
        residual = _compose(f, inverse, width)
        residual[1] = (residual[1] - 1) % MODULUS
        slope = _compose(derivative, inverse, width)
        reciprocal = [inverse_linear] + [0] * (width - 1)
        for i in range(1, width):
            reciprocal[i] = -inverse_linear * sum(slope[j] * reciprocal[i - j]
                                                   for j in range(1, i + 1)) % MODULUS
        correction = _multiply(residual, reciprocal, width)
        for i in range(width):
            inverse[i] = (inverse[i] - correction[i]) % MODULUS
        precision = width
    return 8 * n, b"".join(struct.pack("<q", value) for value in inverse)
