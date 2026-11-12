"""Cipolla roots and the binomial expansion of sqrt(1+u)."""

from __future__ import annotations

from collections.abc import Sequence
import struct

P = 998_244_353
LIMIT = 64
PARSE_LIMIT = 66


def _pair_product(left: tuple[int, int], right: tuple[int, int], radical: int) -> tuple[int, int]:
    a, b = left
    c, d = right
    return ((a * c + b * d * radical) % P, (a * d + b * c) % P)


def _pair_power(base: tuple[int, int], exponent: int, radical: int) -> tuple[int, int]:
    result = (1, 0)
    while exponent:
        if exponent & 1:
            result = _pair_product(result, base, radical)
        base = _pair_product(base, base, radical)
        exponent >>= 1
    return result


def _cipolla_canonical_root(value: int) -> int | None:
    if value == 0:
        return 0
    if pow(value, (P - 1) // 2, P) != 1:
        return None
    probe = 1
    while True:
        radical = (probe * probe - value) % P
        if pow(radical, (P - 1) // 2, P) == P - 1:
            break
        probe += 1
    root, _ = _pair_power((probe, 1), (P + 1) // 2, radical)
    return min(root, P - root)


def _convolution(left: list[int], right: list[int], width: int) -> list[int]:
    product = [0] * width
    for i, a in enumerate(left):
        for j, b in enumerate(right):
            if i + j >= width:
                break
            product[i + j] = (product[i + j] + a * b) % P
    return product


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
    count_words = len(words)
    if count_words < 2 or count_words > PARSE_LIMIT:
        return -1, b""
    if input_length is not None and (type(input_length) is not int or input_length != count_words):
        return -1, b""
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63) for word in words):
        return -1, b""
    n = words[0]
    if n < 1 or n > LIMIT or count_words != n + 1:
        return -1, b""
    coefficients = list(words[1:])
    if any(coefficient < 0 or coefficient >= P for coefficient in coefficients):
        return -1, b""
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < 8 * n)):
        return -2, b""

    first = next((index for index, value in enumerate(coefficients) if value), None)
    if first is None:
        return 8 * n, bytes(8 * n)
    if first & 1:
        return 8, struct.pack("<q", -1)

    offset = first // 2
    leading = _cipolla_canonical_root(coefficients[first])
    if leading is None:
        return 8, struct.pack("<q", -1)
    width = n - first
    inverse_leading = pow(coefficients[first], P - 2, P)
    normalized = [0] * width
    for degree in range(width):
        normalized[degree] = coefficients[first + degree] * inverse_leading % P
    normalized[0] = 0

    expansion = [0] * width
    expansion[0] = 1
    power = [0] * width
    power[0] = 1
    binomial = 1
    for exponent in range(1, width):
        power = _convolution(power, normalized, width)
        binomial = (binomial * (3 - 2 * exponent) *
                    pow(2 * exponent, P - 2, P)) % P
        for degree, coefficient in enumerate(power):
            expansion[degree] = (expansion[degree] + binomial * coefficient) % P

    result = [0] * n
    for degree in range(width):
        result[offset + degree] = leading * expansion[degree] % P
    encoded = b"".join(struct.pack("<q", coefficient) for coefficient in result)
    return 8 * n, encoded


def validate_output(words, output: bytes, **options) -> bool:
    status, expected = expected_output(words, **options)
    return status >= 0 and len(output) == status and output == expected
