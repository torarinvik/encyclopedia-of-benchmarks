"""Exact-rational oracle for the bounded modular Bernoulli-number profile."""

from fractions import Fraction
from math import comb

MODULUS = 998_244_353
MAX_N = 32
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_OUTPUT_BYTES = 4 * (MAX_N + 1)


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)`` for input ``[N]``.

    The oracle builds the rational sequence before reducing it modulo the
    prime. This deliberately differs from the ports, which carry out every
    recurrence operation in the finite field.
    """
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or input_length > MAX_PARSEABLE_INPUT_LENGTH or len(values) != 1):
        return -1, b""
    n = values[0]
    if type(n) is not int or not 0 <= n <= MAX_N:
        return -1, b""

    required = 4 * (n + 1)
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if (type(output_is_null) is not bool or type(capacity) is not int
            or capacity < 0):
        return -2, b""
    if output_is_null or capacity < required:
        return -2, b""

    numbers = [Fraction(1, 1)]
    for m in range(1, n + 1):
        weighted_sum = sum(
            comb(m + 1, k) * numbers[k]
            for k in range(m)
        )
        numbers.append(-weighted_sum / (m + 1))

    encoded = bytearray()
    for number in numbers:
        residue = (number.numerator % MODULUS) * pow(
            number.denominator, -1, MODULUS
        ) % MODULUS
        encoded.extend(residue.to_bytes(4, "little"))
    result = bytes(encoded)
    return len(result), result
