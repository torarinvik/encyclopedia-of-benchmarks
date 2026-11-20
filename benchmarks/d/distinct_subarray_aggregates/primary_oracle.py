"""Suffix-range compression for distinct idempotent subarray aggregates."""

from __future__ import annotations

from collections.abc import Sequence
from math import gcd

MAX_N = 64
MAX_VALUE = 255
MAX_VALID_INPUT_LENGTH = 2 + MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_SUFFIX_VALUES = 9
MAX_SECONDARY_COUNT = MAX_N * MAX_SUFFIX_VALUES
PACKING_MULTIPLIER = 1024
MAX_AGGREGATE_SUM = MAX_VALUE * MAX_N * (MAX_N + 1) // 2
MAX_RESULT = MAX_AGGREGATE_SUM * PACKING_MULTIPLIER + MAX_SECONDARY_COUNT
MAX_WORKSPACE_BYTES = 4096
INVALID_RESULT = -1


def _combine(mode: int, left: int, right: int) -> int:
    if mode == 0:
        return gcd(left, right)
    if mode == 1:
        return left | right
    return left & right


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    mode, n = values[:2]
    if mode not in (0, 1, 2) or not 0 <= n <= MAX_N or len(values) != 2 + n:
        return None
    data = list(values[2:])
    if any(not 0 <= value <= MAX_VALUE for value in data):
        return None
    return mode, data


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return the packed aggregate sum and suffix-distinct count."""
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    mode, data = parsed
    segments: list[tuple[int, int, int]] = []
    aggregate_sum = 0
    suffix_distinct_count = 0
    for right, value in enumerate(data):
        extended = [(_combine(mode, old_value, value), left, end)
                    for old_value, left, end in segments]
        extended.append((value, right, right))
        merged: list[tuple[int, int, int]] = []
        for aggregate, left, end in extended:
            if merged and merged[-1][0] == aggregate:
                previous, first, _ = merged[-1]
                merged[-1] = (previous, first, end)
            else:
                merged.append((aggregate, left, end))
        segments = merged
        suffix_distinct_count += len(segments)
        for aggregate, left, end in segments:
            aggregate_sum += aggregate * (end - left + 1)
    return aggregate_sum * PACKING_MULTIPLIER + suffix_distinct_count
