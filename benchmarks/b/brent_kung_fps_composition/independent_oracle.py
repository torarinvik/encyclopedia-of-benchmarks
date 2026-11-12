"""Independent Horner oracle for formal power-series composition."""
from __future__ import annotations

from collections.abc import Sequence
import struct

P = 998_244_353
LIMIT = 32
PARSE_LIMIT = 66
INVALID = -1
NO_SPACE = -2
I64_LOW = -(1 << 63)
I64_HIGH = (1 << 63) - 1


def _bad() -> tuple[int, bytes]:
    return INVALID, b""


def _product_by_coefficient(left: list[int], right: list[int], n: int) -> list[int]:
    result = [0] * n
    for degree in range(n):
        total = 0
        for left_degree in range(degree + 1):
            total += left[left_degree] * right[degree - left_degree]
        result[degree] = total % P
    return result


def expected_output(
    words: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or not isinstance(words, (list, tuple))
            or len(words) < 3 or len(words) > PARSE_LIMIT
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(words)))):
        return _bad()
    if any(type(word) is not int or not I64_LOW <= word <= I64_HIGH for word in words):
        return _bad()
    n = words[0]
    if n < 1 or n > LIMIT or len(words) != 1 + 2 * n:
        return _bad()
    coefficients = list(words[1:1 + n])
    substitution = list(words[1 + n:])
    if any(value < 0 or value >= P for value in coefficients + substitution) or substitution[0] != 0:
        return _bad()
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return _bad()
    required = 8 * n
    if output_is_null or (output_capacity is not None and output_capacity < required):
        return NO_SPACE, b""

    power = [0] * n
    power[0] = 1
    result = [0] * n
    for coefficient in coefficients:
        for degree in range(n):
            result[degree] = (result[degree] + coefficient * power[degree]) % P
        power = _product_by_coefficient(power, substitution, n)
    raw = b"".join(struct.pack("<q", value) for value in result)
    return required, raw
