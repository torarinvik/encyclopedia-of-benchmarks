"""Lagrange-inversion oracle using binomial expansion and truncated products."""

from __future__ import annotations

from collections.abc import Sequence
import struct

P = 998_244_353
MIN_SIZE = 2
LIMIT = 16
PARSE_LIMIT = 18


def _product(left: list[int], right: list[int], width: int) -> list[int]:
    result = [0] * width
    for i, first in enumerate(left):
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
        return -1, b""
    if input_is_null or not isinstance(words, (list, tuple)):
        return -1, b""
    size = len(words)
    if size < MIN_SIZE + 1 or size > PARSE_LIMIT:
        return -1, b""
    if input_length is not None and (type(input_length) is not int or input_length != size):
        return -1, b""
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63) for word in words):
        return -1, b""
    n = words[0]
    if not MIN_SIZE <= n <= LIMIT or size != n + 1:
        return -1, b""
    coefficients = list(words[1:])
    if any(coefficient < 0 or coefficient >= P for coefficient in coefficients):
        return -1, b""
    if coefficients[0] != 0 or coefficients[1] == 0:
        return -1, b""
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < 8 * n)):
        return -2, b""

    inverse_linear = pow(coefficients[1], P - 2, P)
    inverse_series = [0] * n
    for degree in range(1, n):
        width = degree
        normalized_tail = [0] * width
        for index in range(1, width):
            normalized_tail[index] = coefficients[index + 1] * inverse_linear % P
        power = [0] * width
        power[0] = 1
        binomial = 1
        target_sum = 0
        for exponent in range(width):
            if exponent > 0:
                power = _product(power, normalized_tail, width)
                binomial = (binomial * (-degree - exponent + 1) *
                            pow(exponent, P - 2, P)) % P
            target_sum = (target_sum + binomial * power[degree - 1]) % P
        scale = pow(inverse_linear, degree, P) * pow(degree, P - 2, P) % P
        inverse_series[degree] = target_sum * scale % P

    encoded = b"".join(struct.pack("<q", coefficient) for coefficient in inverse_series)
    return 8 * n, encoded


def validate_output(words, output: bytes, **options) -> bool:
    status, expected = expected_output(words, **options)
    return status >= 0 and len(output) == status and output == expected
