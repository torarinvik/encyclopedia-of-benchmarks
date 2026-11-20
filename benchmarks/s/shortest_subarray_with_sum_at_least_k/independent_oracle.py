"""Quadratic enumeration reference for the shortest qualifying subarray."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_COUNT,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALUE,
    MAX_TARGET,
    MIN_TARGET,
    MIN_VALUE,
)


def _decode(
    values: Sequence[int] | None,
    input_length: int | None,
    input_is_null: bool,
) -> tuple[int, list[int]] | None:
    if (
        type(input_is_null) is not bool
        or input_is_null
        or not isinstance(values, (list, tuple))
        or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    target, count = values[0], values[1]
    if not MIN_TARGET <= target <= MAX_TARGET or not 0 <= count <= MAX_COUNT:
        return None
    if len(values) != count + 2:
        return None
    sequence = list(values[2:])
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in sequence):
        return None
    return target, sequence


def expected_output(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    decoded = _decode(values, input_length, input_is_null)
    if decoded is None:
        return -1
    target, sequence = decoded
    best = len(sequence) + 1
    for start in range(len(sequence)):
        total = 0
        for end in range(start, len(sequence)):
            total += sequence[end]
            if total >= target:
                best = min(best, end - start + 1)
    return best if best <= len(sequence) else 0
