"""Oracle for the pinned Python Fraction continued-fraction conversion."""

from __future__ import annotations

from fractions import Fraction
import struct

MAX_ABS_INPUT = 1_000_000
MAX_COEFFICIENTS = 32
MAX_OUTPUT_LENGTH = MAX_COEFFICIENTS * 8


def coefficients(numerator: int, denominator: int) -> list[int]:
    value = Fraction(numerator, denominator)
    current_numerator, current_denominator = value.as_integer_ratio()
    result: list[int] = []
    while True:
        integer_part = current_numerator // current_denominator
        result.append(integer_part)
        current_numerator -= integer_part * current_denominator
        if current_numerator == 0:
            return result
        current_numerator, current_denominator = current_denominator, current_numerator


def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) != 2
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    numerator, denominator = values
    if (abs(numerator) > MAX_ABS_INPUT or abs(denominator) > MAX_ABS_INPUT
            or denominator == 0):
        return -1, b""
    result = b"".join(struct.pack("<q", value) for value in coefficients(numerator, denominator))
    if len(result) > MAX_OUTPUT_LENGTH:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if capacity is not None and len(result) > capacity:
        return -2, b""
    return len(result), result
