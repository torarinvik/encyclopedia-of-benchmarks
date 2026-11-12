"""Truncated repeated-squaring oracle for formal-series powers."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_N = 32
MAX_EXPONENT = 1_000_000_000_000_000_000
MAX_INPUT_LENGTH = 2 + MAX_N
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _multiply_truncated(left: list[int], right: list[int]) -> list[int]:
    n = len(left)
    product = [0] * n
    for i, a in enumerate(left):
        if a == 0:
            continue
        for j in range(n - i):
            product[i + j] = (product[i + j] + a * right[j]) % MODULUS
    return product


def _power_truncated(coefficients: list[int], exponent: int) -> list[int]:
    result = [1] + [0] * (len(coefficients) - 1)
    base = coefficients[:]
    while exponent > 0:
        if exponent & 1:
            result = _multiply_truncated(result, base)
        exponent >>= 1
        if exponent:
            base = _multiply_truncated(base, base)
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
    n, exponent = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= exponent <= MAX_EXPONENT or len(values) != 2 + n:
        return INVALID, b""
    coefficients = list(values[2:])
    if any(not 0 <= coefficient < MODULUS for coefficient in coefficients):
        return INVALID, b""

    byte_count = 8 * n
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return OUTPUT_ERROR, b""
    powered = _power_truncated(coefficients, exponent)
    encoded = b"".join(struct.pack("<q", coefficient) for coefficient in powered)
    return byte_count, encoded
