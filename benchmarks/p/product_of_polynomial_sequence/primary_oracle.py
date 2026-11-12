"""Balanced pairwise polynomial-product oracle for a bounded profile."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_POLYNOMIALS = 6
MAX_DEGREE = 4
MAX_INPUT_LENGTH = 38
MAX_OUTPUT_BYTES = 200
MAX_WORKSPACE_BYTES = 1_536
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _multiply(left: list[int], right: list[int]) -> list[int]:
    product = [0] * (len(left) + len(right) - 1)
    for i, a in enumerate(left):
        for j, b in enumerate(right):
            product[i + j] = (product[i + j] + a * b) % MODULUS
    return product


def _parse(values: Sequence[int] | None, input_is_null: bool,
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
    polynomials: list[list[int]] = []
    cursor = 1
    for _ in range(count):
        if cursor >= len(values):
            return None
        degree = values[cursor]
        cursor += 1
        if not 0 <= degree <= MAX_DEGREE or cursor + degree + 1 > len(values):
            return None
        coefficients = list(values[cursor:cursor + degree + 1])
        cursor += degree + 1
        if any(not 0 <= coefficient < MODULUS for coefficient in coefficients):
            return None
        if coefficients[-1] == 0:
            return None
        polynomials.append(coefficients)
    if cursor != len(values):
        return None
    return polynomials


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID, b""
    polynomials = _parse(values, input_is_null, input_length)
    if polynomials is None:
        return INVALID, b""

    degree_sum = sum(len(poly) - 1 for poly in polynomials)
    byte_count = 8 * (degree_sum + 1)
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return OUTPUT_ERROR, b""

    if not polynomials:
        product = [1]
    else:
        level = polynomials
        while len(level) > 1:
            next_level: list[list[int]] = []
            for index in range(0, len(level), 2):
                if index + 1 == len(level):
                    next_level.append(level[index])
                else:
                    next_level.append(_multiply(level[index], level[index + 1]))
            level = next_level
        product = level[0]
    encoded = b"".join(struct.pack("<q", coefficient) for coefficient in product)
    return byte_count, encoded
