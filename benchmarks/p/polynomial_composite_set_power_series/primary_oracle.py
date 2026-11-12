"""Horner composition oracle for a square-zero set power series."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_N = 4
MAX_COEFFICIENTS = 8
MAX_VALID_INPUT_LENGTH = 2 + MAX_COEFFICIENTS + (1 << MAX_N)
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (1 << MAX_N)
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _subset_product(left: list[int], right: list[int]) -> list[int]:
    """Multiply dense mask series by subset convolution."""
    product = [0] * len(left)
    for mask in range(len(left)):
        total = 0
        subset = mask
        while True:
            total = (total + left[subset] * right[mask ^ subset]) % MODULUS
            if subset == 0:
                break
            subset = (subset - 1) & mask
        product[mask] = total
    return product


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[int], list[int]] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    count, n = values[0], values[1]
    if not 0 <= count <= MAX_COEFFICIENTS or not 0 <= n <= MAX_N:
        return None
    size = 1 << n
    if len(values) != 2 + count + size:
        return None
    polynomial = list(values[2:2 + count])
    series = list(values[2 + count:])
    if any(not 0 <= x < MODULUS for x in polynomial + series):
        return None
    return n, polynomial, series


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID, b""
    n, polynomial, series = parsed
    byte_count = 8 * (1 << n)
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return OUTPUT_ERROR, b""

    result = [0] * (1 << n)
    for coefficient in reversed(polynomial):
        result = _subset_product(result, series)
        result[0] = (result[0] + coefficient) % MODULUS
    return byte_count, b"".join(struct.pack("<q", x) for x in result)
