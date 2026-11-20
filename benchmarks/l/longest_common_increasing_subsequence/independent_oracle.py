"""Matching-pair DAG reference for LCIS length."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import I64_MAX, I64_MIN, MAX_N, MAX_VALUE, MIN_VALUE


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[list[int], list[int]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= 67:
        return None
    if any(type(value) is not int or value < I64_MIN or value > I64_MAX
           for value in values):
        return None
    declared = len(values) if input_length is None else input_length
    if type(declared) is not int or declared != len(values):
        return None
    n, m = values[0], values[1]
    if type(n) is not int or type(m) is not int or not 0 <= n <= MAX_N or not 0 <= m <= MAX_N:
        return None
    if len(values) != 2 + n + m:
        return None
    first = list(values[2:2 + n])
    second = list(values[2 + n:])
    if any(value < MIN_VALUE or value > MAX_VALUE for value in first + second):
        return None
    return first, second


def _lcis_length_as_longest_path(first: list[int], second: list[int]) -> int:
    pairs = [
        (i, j, value)
        for i, value in enumerate(first)
        for j, other in enumerate(second)
        if value == other
    ]
    ending_here = [1] * len(pairs)
    best = 0
    for index, (i, j, value) in enumerate(pairs):
        for earlier in range(index):
            prev_i, prev_j, prev_value = pairs[earlier]
            if prev_i < i and prev_j < j and prev_value < value:
                ending_here[index] = max(ending_here[index], ending_here[earlier] + 1)
        best = max(best, ending_here[index])
    return best


def expected_result(values: Sequence[int] | None, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1
    return _lcis_length_as_longest_path(*parsed)
