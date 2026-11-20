"""Direct divisor-pair reference for the filtered-number list."""

from __future__ import annotations

import struct
from collections.abc import Sequence

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_LIMIT,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    MIN_LIMIT,
)


def _divisor_count_by_pairs(value: int) -> int:
    count = 0
    divisor = 1
    while divisor <= value // divisor:
        if value % divisor == 0:
            count += 1
            if divisor != value // divisor:
                count += 1
        divisor += 1
    return count


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
    return limit if MIN_LIMIT <= limit <= MAX_LIMIT else None


def selected_numbers_by_pairs(limit: int) -> list[int]:
    return [n for n in range(1, limit)
            if (count := _divisor_count_by_pairs(n)) != 2 and _is_prime(count)]


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
    encoded = b"".join(
        struct.pack("<q", value) for value in selected_numbers_by_pairs(limit)
    )
    actual_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if output_is_null or actual_capacity < len(encoded):
        return -2, b""
    return len(encoded), encoded
