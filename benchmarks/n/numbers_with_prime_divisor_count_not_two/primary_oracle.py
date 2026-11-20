"""Divisor-count sieve reference for the bounded filtered-number list."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MIN_LIMIT = 1
MAX_LIMIT = 1_000
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_VALID_INPUT_LENGTH = 1
MAX_OUTPUT_ELEMENTS = 16
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_ELEMENTS
WORKSPACE_BYTES = 4_096
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _is_prime(value: int) -> bool:
    if value < 2:
        return False
    divisor = 2
    while divisor <= value // divisor:
        if value % divisor == 0:
            return False
        divisor += 1
    return True


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> int | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    if len(values) != MAX_VALID_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX
           for value in values):
        return None
    limit = values[0]
    if not MIN_LIMIT <= limit <= MAX_LIMIT:
        return None
    return limit


def selected_numbers(limit: int) -> list[int]:
    """Return qualifying n using a divisor-count sieve over [1, limit)."""
    counts = [0] * limit
    for divisor in range(1, limit):
        for multiple in range(divisor, limit, divisor):
            counts[multiple] += 1
    return [n for n in range(1, limit)
            if counts[n] != 2 and _is_prime(counts[n])]


def expected_output(values: Sequence[int] | None,
                    capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    limit = _parse(values, input_length, input_is_null)
    if limit is None:
        return -1, b""
    if (type(output_is_null) is not bool or
            (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -2, b""
    numbers = selected_numbers(limit)
    encoded = b"".join(struct.pack("<q", value) for value in numbers)
    actual_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if output_is_null or actual_capacity < len(encoded):
        return -2, b""
    return len(encoded), encoded
