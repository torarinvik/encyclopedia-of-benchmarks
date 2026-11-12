"""Sequential-fold polynomial-product oracle, independent of the product tree."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_POLYNOMIALS = 6
MAX_DEGREE = 4
MAX_INPUT_LENGTH = 38
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> list[list[int]] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    count = values[0]
    if not 0 <= count <= MAX_POLYNOMIALS:
        return None
    cursor = 1
    items: list[list[int]] = []
    while len(items) < count:
        if cursor == len(values):
            return None
        degree = values[cursor]
        cursor += 1
        if degree < 0 or degree > MAX_DEGREE or cursor + degree + 1 > len(values):
            return None
        coefficients = [values[cursor + offset] for offset in range(degree + 1)]
        cursor += degree + 1
        if any(coefficient < 0 or coefficient >= MODULUS for coefficient in coefficients):
            return None
        if not coefficients or coefficients[-1] == 0:
            return None
        items.append(coefficients)
    if cursor != len(values):
        return None
    return items


def _fold_product(items: list[list[int]]) -> list[int]:
    result = [1]
    for polynomial in items:
        accumulated = [0] * (len(result) + len(polynomial) - 1)
        for old_degree, old_coefficient in enumerate(result):
            for new_degree, new_coefficient in enumerate(polynomial):
                slot = old_degree + new_degree
                accumulated[slot] = (accumulated[slot] + old_coefficient * new_coefficient) % MODULUS
        result = accumulated
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
    items = _decode(values, input_is_null, input_length)
    if items is None:
        return INVALID, b""
    coefficient_count = 1 + sum(len(item) - 1 for item in items)
    byte_count = 8 * coefficient_count
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return OUTPUT_ERROR, b""
    product = _fold_product(items)
    encoded = b"".join(struct.pack("<q", coefficient) for coefficient in product)
    return byte_count, encoded
