"""Quadratic derivative-recurrence oracle for formal power series exp."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_N = 64
MAX_INPUT_LENGTH = 66
MAX_OUTPUT_BYTES = 512
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _invalid() -> tuple[int, bytes]:
    return INVALID, b""


def _integer_inverses(count: int) -> list[int]:
    inverses = [0] * count
    if count > 1:
        inverses[1] = 1
    for value in range(2, count):
        inverses[value] = MODULUS - (MODULUS // value) * inverses[MODULUS % value] % MODULUS
    return inverses


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
    if len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return _invalid()
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return _invalid()
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return _invalid()
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != n + 1:
        return _invalid()
    coefficients = values[1:]
    if any(not 0 <= value < MODULUS for value in coefficients) or coefficients[0] != 0:
        return _invalid()

    byte_count = 8 * n
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return OUTPUT_ERROR, b""

    integer_inverses = _integer_inverses(n)
    exponential = [0] * n
    exponential[0] = 1
    for degree in range(1, n):
        derivative_product = 0
        for index in range(1, degree + 1):
            derivative_product = (derivative_product + index * coefficients[index] *
                                  exponential[degree - index]) % MODULUS
        exponential[degree] = derivative_product * integer_inverses[degree] % MODULUS
    encoded = b"".join(struct.pack("<q", value) for value in exponential)
    return byte_count, encoded
