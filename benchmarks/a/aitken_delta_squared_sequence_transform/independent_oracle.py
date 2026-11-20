"""Fraction-based difference-quotient oracle for the Aitken transform."""

from __future__ import annotations

from fractions import Fraction

MAX_TERMS = 64
VALUE_LIMIT = 1_000_000


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
    if input_is_null or length != len(input_values) or not 3 <= length <= 66:
        return -1, b""
    n = input_values[0]
    if not 2 <= n <= MAX_TERMS or length != n + 1:
        return -1, b""
    sequence = input_values[1:]
    if any(not -VALUE_LIMIT <= value <= VALUE_LIMIT for value in sequence):
        return -1, b""
    output_length = 16 * (n - 2)
    if output_is_null or (output_capacity is not None and output_capacity < output_length):
        return -2, b""

    output = bytearray()
    for first, middle, last in zip(sequence, sequence[1:], sequence[2:]):
        first_difference = middle - first
        second_difference = (last - middle) - first_difference
        if second_difference == 0:
            result = Fraction(first, 1) if first == middle == last else None
        else:
            result = Fraction(first, 1) - Fraction(first_difference * first_difference, second_difference)
        if result is None:
            output.extend(bytes(16))
        else:
            output.extend(_i64_bytes(result.numerator))
            output.extend(_i64_bytes(result.denominator))
    return len(output), bytes(output)
