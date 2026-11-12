"""Subset-cardinality recurrence for exponential in the square-zero algebra."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_N = 5
MAX_INPUT_LENGTH = 1 + (1 << MAX_N)
MAX_OUTPUT_BYTES = 8 * (1 << MAX_N)
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _popcount(mask: int) -> int:
    return mask.bit_count()


def _subset_exponential(coefficients: list[int], n: int) -> list[int]:
    size = 1 << n
    inverse = [0] * (n + 1)
    if n:
        inverse[1] = 1
    for k in range(2, n + 1):
        inverse[k] = MODULUS - (MODULUS // k) * inverse[MODULUS % k] % MODULUS

    result = [0] * size
    result[0] = 1
    for mask in range(1, size):
        total = 0
        subset = mask
        while subset:
            total += _popcount(subset) * coefficients[subset] * result[mask ^ subset]
            total %= MODULUS
            subset = (subset - 1) & mask
        result[mask] = total * inverse[_popcount(mask)] % MODULUS
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
    if len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return INVALID, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID, b""

    n = values[0]
    if not 0 <= n <= MAX_N:
        return INVALID, b""
    size = 1 << n
    if len(values) != 1 + size:
        return INVALID, b""
    coefficients = list(values[1:])
    if coefficients[0] != 0 or any(not 0 <= value < MODULUS for value in coefficients):
        return INVALID, b""

    byte_count = size * 8
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return OUTPUT_ERROR, b""
    result = _subset_exponential(coefficients, n)
    return byte_count, b"".join(struct.pack("<q", value) for value in result)
