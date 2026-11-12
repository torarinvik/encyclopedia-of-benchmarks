"""Independent formal-log oracle via the alternating power-series definition."""

from __future__ import annotations

from collections.abc import Sequence
import struct

P = 998_244_353
LIMIT = 64
PARSE_LIMIT = 66


def _invalid() -> tuple[int, bytes]:
    return -1, b""


def _inverse(value: int) -> int:
    old_r, r = P, value
    old_s, s = 0, 1
    while r:
        quotient = old_r // r
        old_r, r = r, old_r - quotient * r
        old_s, s = s, old_s - quotient * s
    return old_s % P


def _product(left: list[int], right: list[int], width: int) -> list[int]:
    result = [0] * width
    for i, first in enumerate(left):
        if i >= width:
            break
        for j, second in enumerate(right):
            if i + j >= width:
                break
            result[i + j] = (result[i + j] + first * second) % P
    return result


def expected_output(
    words: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return _invalid()
    if input_is_null or not isinstance(words, (list, tuple)):
        return _invalid()
    size = len(words)
    if size < 2 or size > PARSE_LIMIT:
        return _invalid()
    if input_length is not None and (type(input_length) is not int or input_length != size):
        return _invalid()
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63) for word in words):
        return _invalid()
    count = words[0]
    if count < 1 or count > LIMIT or size != count + 1:
        return _invalid()
    coefficients = list(words[1:])
    if coefficients[0] != 1 or any(coefficient < 0 or coefficient >= P for coefficient in coefficients):
        return _invalid()

    byte_count = 8 * count
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return -2, b""

    h = coefficients[:]
    h[0] = 0
    power = [0] * count
    power[0] = 1
    logarithm = [0] * count
    for exponent in range(1, count):
        power = _product(power, h, count)
        term = power[:]
        scale = _inverse(exponent)
        if exponent % 2 == 0:
            scale = -scale
        for degree, coefficient in enumerate(term):
            logarithm[degree] = (logarithm[degree] + scale * coefficient) % P
    encoded = b"".join(struct.pack("<q", coefficient) for coefficient in logarithm)
    return byte_count, encoded


def validate_output(values, output: bytes, **options) -> bool:
    status, expected = expected_output(values, **options)
    return status >= 0 and len(output) == status and output == expected
