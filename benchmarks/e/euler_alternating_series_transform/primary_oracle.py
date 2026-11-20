"""Forward-difference-triangle reference for the finite Euler transform."""

from __future__ import annotations

from math import gcd

MAX_TERMS = 16
VALUE_LIMIT = 1_000_000
MAX_PARSEABLE_INPUT_LENGTH = 18
MAX_OUTPUT_BYTES = 16
WORKSPACE_BYTES = 0


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
    if any(not -VALUE_LIMIT <= value <= VALUE_LIMIT for value in input_values[1:]):
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < MAX_OUTPUT_BYTES):
        return -2, b""

    differences = input_values[1:].copy()
    numerator = 0
    for order in range(n):
        weighted = differences[0] << (n - order - 1)
        numerator += weighted if order % 2 == 0 else -weighted
        differences = [differences[index + 1] - differences[index]
                       for index in range(len(differences) - 1)]
    denominator = 1 << n
    divisor = gcd(abs(numerator), denominator)
    numerator //= divisor
    denominator //= divisor
    output = _i64_bytes(numerator) + _i64_bytes(denominator)
    return len(output), output
