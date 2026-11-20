"""Binomial-coefficient exact-fraction reference for Euler's finite transform."""

from __future__ import annotations

from fractions import Fraction
from math import comb

MAX_TERMS = 16
VALUE_LIMIT = 1_000_000
MAX_PARSEABLE_INPUT_LENGTH = 18
MAX_OUTPUT_BYTES = 16


def _i64_bytes(value: int) -> bytes:
    return int(value).to_bytes(8, "little", signed=True)


def expected_output(
    input_values: list[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    length = len(input_values) if input_length is None else input_length
    if input_is_null or length != len(input_values) or not 2 <= length <= MAX_PARSEABLE_INPUT_LENGTH:
        return -1, b""
    n = input_values[0]
    if not 1 <= n <= MAX_TERMS or length != n + 1:
        return -1, b""
    terms = input_values[1:]
    if any(value < -VALUE_LIMIT or value > VALUE_LIMIT for value in terms):
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < MAX_OUTPUT_BYTES):
        return -2, b""

    result = Fraction(0, 1)
    for order in range(n):
        difference = sum(
            (-1 if index % 2 else 1) * comb(order, index) * terms[order - index]
            for index in range(order + 1)
        )
        contribution = Fraction(difference, 1 << (order + 1))
        result += contribution if order % 2 == 0 else -contribution
    output = _i64_bytes(result.numerator) + _i64_bytes(result.denominator)
    return len(output), output
