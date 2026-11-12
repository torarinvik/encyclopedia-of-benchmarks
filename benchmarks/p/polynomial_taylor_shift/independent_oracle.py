"""Independent binomial-expansion oracle for a bounded Taylor shift."""

from __future__ import annotations

from collections.abc import Sequence
import math
import struct

try:
    from .primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_N, MODULUS, OUTPUT_ERROR,
    )
except ImportError:  # Direct import from this package directory.
    from primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_N, MODULUS, OUTPUT_ERROR,
    )


def _binomial_shift(coefficients: list[int], shift: int) -> list[int]:
    result = [0] * len(coefficients)
    for source_degree, coefficient in enumerate(coefficients):
        for target_degree in range(source_degree + 1):
            term = coefficient * math.comb(source_degree, target_degree)
            term *= pow(shift, source_degree - target_degree, MODULUS)
            result[target_degree] = (result[target_degree] + term) % MODULUS
    return result


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID, b""
    if len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return INVALID, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID, b""
    n, shift = values[:2]
    if not 1 <= n <= MAX_N or len(values) != 2 + n:
        return INVALID, b""
    coefficients = list(values[2:])
    if not 0 <= shift < MODULUS or any(not 0 <= coefficient < MODULUS for coefficient in coefficients):
        return INVALID, b""

    byte_count = 8 * n
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return OUTPUT_ERROR, b""
    shifted = _binomial_shift(coefficients, shift)
    return byte_count, b"".join(struct.pack("<q", coefficient) for coefficient in shifted)
