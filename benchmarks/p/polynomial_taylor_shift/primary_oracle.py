"""Direct Horner recurrence for a bounded polynomial Taylor shift."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_N = 64
MAX_INPUT_LENGTH = 2 + MAX_N
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _horner_shift(coefficients: list[int], shift: int) -> list[int]:
    result = [0] * len(coefficients)
    processed = 0
    for coefficient in reversed(coefficients):
        for degree in range(processed, 0, -1):
            result[degree] = (result[degree] * shift + result[degree - 1]) % MODULUS
        result[0] = (result[0] * shift + coefficient) % MODULUS
        processed += 1
    return result


def _invalid() -> tuple[int, bytes]:
    return INVALID, b""


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
    if len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return _invalid()
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return _invalid()
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return _invalid()
    n, shift = values[:2]
    if not 1 <= n <= MAX_N or len(values) != 2 + n:
        return _invalid()
    coefficients = list(values[2:])
    if not 0 <= shift < MODULUS or any(not 0 <= coefficient < MODULUS for coefficient in coefficients):
        return _invalid()

    byte_count = 8 * n
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return OUTPUT_ERROR, b""
    shifted = _horner_shift(coefficients, shift)
    return byte_count, b"".join(struct.pack("<q", coefficient) for coefficient in shifted)
