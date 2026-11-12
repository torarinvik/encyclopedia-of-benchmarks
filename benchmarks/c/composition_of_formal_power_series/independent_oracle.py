"""Independent verifier by summing coefficient-scaled powers of the inner series."""

from __future__ import annotations

from collections.abc import Sequence
import struct

P = 998_244_353
LIMIT = 16
PARSE_LIMIT = 34


def _invalid() -> tuple[int, bytes]:
    return -1, b""


def _truncated_product(left: list[int], right: list[int], width: int) -> list[int]:
    product = [0] * width
    for left_degree, left_value in enumerate(left):
        for right_degree, right_value in enumerate(right):
            degree = left_degree + right_degree
            if degree >= width:
                continue
            product[degree] = (product[degree] + left_value * right_value) % P
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
    if size < 3 or size > PARSE_LIMIT:
        return _invalid()
    if input_length is not None and (type(input_length) is not int or input_length != size):
        return _invalid()
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63) for word in words):
        return _invalid()
    count = words[0]
    if count < 1 or count > LIMIT or size != 1 + 2 * count:
        return _invalid()
    outer = list(words[1:1 + count])
    inner = list(words[1 + count:])
    if any(value < 0 or value >= P for value in outer + inner) or inner[0] != 0:
        return _invalid()

    byte_count = 8 * count
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return -2, b""

    power = [0] * count
    power[0] = 1
    total = [0] * count
    for coefficient in outer:
        for degree in range(count):
            total[degree] = (total[degree] + coefficient * power[degree]) % P
        power = _truncated_product(power, inner, count)
    encoded = b"".join(struct.pack("<q", value) for value in total)
    return byte_count, encoded
