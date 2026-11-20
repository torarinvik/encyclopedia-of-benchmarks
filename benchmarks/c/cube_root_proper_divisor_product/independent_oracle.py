"""Divisor-count sieve reference for the indexed sequence."""

from __future__ import annotations

from collections.abc import Sequence

MAX_K = 50_000
MAX_RESULT = 600_000
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


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
    k = values[0]
    return k if 1 <= k <= MAX_K else None


def _divisor_count_table(limit: int) -> list[int]:
    counts = [0] * (limit + 1)
    for divisor in range(1, limit + 1):
        for multiple in range(divisor, limit + 1, divisor):
            counts[multiple] += 1
    return counts


def expected_result(values: Sequence[int] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    k = _parse(values, input_length, input_is_null)
    if k is None:
        return -1
    if k == 1:
        return 1
    counts = _divisor_count_table(MAX_RESULT)
    target = k - 1
    seen = 0
    for value in range(2, MAX_RESULT + 1):
        if counts[value] == 8:
            seen += 1
            if seen == target:
                return value
    return -1
