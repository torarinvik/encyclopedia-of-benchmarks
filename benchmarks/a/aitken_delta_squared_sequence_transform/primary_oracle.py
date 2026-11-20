"""Direct exact numerator/denominator oracle for Aitken's delta-squared map."""

from __future__ import annotations

from math import gcd

MAX_TERMS = 64
VALUE_LIMIT = 1_000_000
MAX_PARSEABLE_INPUT_LENGTH = 66
MAX_OUTPUT_BYTES = 992
WORKSPACE_BYTES = 0


def _i64_bytes(value: int) -> bytes:
    return int(value).to_bytes(8, "little", signed=True)


def _reduced_pair(numerator: int, denominator: int) -> tuple[int, int]:
    if denominator == 0:
        return (0, 0)
    if denominator < 0:
        numerator = -numerator
        denominator = -denominator
    divisor = gcd(abs(numerator), denominator)
    return numerator // divisor, denominator // divisor


def expected_output(
    input_values: list[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    length = len(input_values) if input_length is None else input_length
    if (input_is_null or length != len(input_values) or length < 3
            or length > MAX_PARSEABLE_INPUT_LENGTH):
        return -1, b""
    n = input_values[0]
    if n < 2 or n > MAX_TERMS or length != n + 1:
        return -1, b""
    sequence = input_values[1:]
    if any(value < -VALUE_LIMIT or value > VALUE_LIMIT for value in sequence):
        return -1, b""
    output_length = 16 * (n - 2)
    if output_is_null or (output_capacity is not None and output_capacity < output_length):
        return -2, b""

    output = bytearray()
    for start in range(n - 2):
        first, middle, last = sequence[start : start + 3]
        numerator = first * last - middle * middle
        denominator = first - 2 * middle + last
        if denominator == 0:
            if first == middle == last:
                numerator, denominator = first, 1
            else:
                numerator, denominator = 0, 0
        else:
            numerator, denominator = _reduced_pair(numerator, denominator)
        output.extend(_i64_bytes(numerator))
        output.extend(_i64_bytes(denominator))
    return len(output), bytes(output)
