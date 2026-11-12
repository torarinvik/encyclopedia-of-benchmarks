"""Triangular power-coefficient recurrence for compositional inversion."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MIN_N = 2
MAX_N = 16
MAX_INPUT_LENGTH = 18
MAX_OUTPUT_BYTES = 128


def _invalid() -> tuple[int, bytes]:
    return -1, b""


def _mod_power(base: int, exponent: int) -> int:
    result = 1
    base %= MODULUS
    while exponent:
        if exponent & 1:
            result = result * base % MODULUS
        base = base * base % MODULUS
        exponent >>= 1
    return result


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return _invalid()
    if input_is_null or not isinstance(values, (list, tuple)):
        return _invalid()
    if len(values) < MIN_N + 1 or len(values) > MAX_INPUT_LENGTH:
        return _invalid()
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return _invalid()
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return _invalid()
    n = values[0]
    if not MIN_N <= n <= MAX_N or len(values) != n + 1:
        return _invalid()
    coefficients = values[1:]
    if any(not 0 <= value < MODULUS for value in coefficients):
        return _invalid()
    if coefficients[0] != 0 or coefficients[1] == 0:
        return _invalid()

    byte_count = 8 * n
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return -2, b""

    inverse_linear = _mod_power(coefficients[1], MODULUS - 2)
    inverse_powers = [[0] * n for _ in range(n)]
    inverse_series = [0] * n
    inverse_series[1] = inverse_linear
    inverse_powers[1][1] = inverse_linear
    for degree in range(2, n):
        for power in range(2, degree + 1):
            coefficient = 0
            for split in range(1, degree):
                coefficient = (coefficient + inverse_powers[power - 1][degree - split] *
                               inverse_series[split]) % MODULUS
            inverse_powers[power][degree] = coefficient
        composed_coefficient = 0
        for power in range(2, degree + 1):
            composed_coefficient = (composed_coefficient +
                                    coefficients[power] * inverse_powers[power][degree]) % MODULUS
        inverse_series[degree] = (-composed_coefficient * inverse_linear) % MODULUS
        inverse_powers[1][degree] = inverse_series[degree]

    encoded = b"".join(struct.pack("<q", coefficient) for coefficient in inverse_series)
    return byte_count, encoded
