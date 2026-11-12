"""Independent Newton-iteration verifier with direct truncated products."""

from __future__ import annotations

from collections.abc import Sequence
import struct

P = 998_244_353
N_LIMIT = 64
PARSE_LIMIT = 66
BYTES_LIMIT = 512


def _invalid() -> tuple[int, bytes]:
    return -1, b""


def _inverse_euclid(value: int) -> int:
    old_r, r = P, value
    old_s, s = 0, 1
    while r:
        quotient = old_r // r
        old_r, r = r, old_r - quotient * r
        old_s, s = s, old_s - quotient * s
    return old_s % P


def _multiply_truncated(left: list[int], right: list[int], width: int) -> list[int]:
    product = [0] * width
    for i, left_value in enumerate(left):
        if i >= width:
            break
        for j, right_value in enumerate(right):
            if i + j >= width:
                break
            product[i + j] = (product[i + j] + left_value * right_value) % P
    return product


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
    if count < 1 or count > N_LIMIT or size != count + 1:
        return _invalid()
    coefficients = list(words[1:])
    if coefficients[0] == 0 or any(coefficient < 0 or coefficient >= P for coefficient in coefficients):
        return _invalid()

    byte_count = 8 * count
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return -2, b""

    current = [_inverse_euclid(coefficients[0])]
    precision = 1
    while precision < count:
        target = min(2 * precision, count)
        product = _multiply_truncated(coefficients[:target], current, target)
        correction = [(-coefficient) % P for coefficient in product]
        correction[0] = (2 - product[0]) % P
        current = _multiply_truncated(current, correction, target)
        precision = target
    encoded = b"".join(struct.pack("<q", coefficient) for coefficient in current)
    return byte_count, encoded
