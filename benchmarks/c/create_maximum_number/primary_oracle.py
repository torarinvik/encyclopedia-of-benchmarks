"""Split enumeration, monotone subsequence selection, and suffix-aware merge."""

from __future__ import annotations

from collections.abc import Sequence

MAX_SOURCE_LENGTH = 6
MAX_PARSEABLE_LENGTH = 16
MAX_OUTPUT_BYTES = 12
WORKSPACE_BYTES = 512


def _parse(
    values: Sequence[int] | None,
    input_is_null: bool,
    input_length: int | None,
) -> tuple[tuple[int, ...], tuple[int, ...], int] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 3 <= len(values) <= MAX_PARSEABLE_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None

    first_length, second_length, requested = values[:3]
    if not 0 <= first_length <= MAX_SOURCE_LENGTH:
        return None
    if not 0 <= second_length <= MAX_SOURCE_LENGTH:
        return None
    if not 0 <= requested <= first_length + second_length:
        return None
    if len(values) != 3 + first_length + second_length:
        return None
    first = tuple(values[3 : 3 + first_length])
    second = tuple(values[3 + first_length :])
    if any(not 0 <= digit <= 9 for digit in first + second):
        return None
    return first, second, requested


def _maximum_subsequence(source: Sequence[int], requested: int) -> tuple[int, ...]:
    deletions = len(source) - requested
    stack: list[int] = []
    for digit in source:
        while deletions and stack and stack[-1] < digit:
            stack.pop()
            deletions -= 1
        stack.append(digit)
    if deletions:
        del stack[-deletions:]
    return tuple(stack)


def _merge(first: Sequence[int], second: Sequence[int]) -> tuple[int, ...]:
    merged: list[int] = []
    i = 0
    j = 0
    while i < len(first) or j < len(second):
        if j == len(second):
            take_first = True
        elif i == len(first):
            take_first = False
        else:
            left_suffix = first[i:]
            right_suffix = second[j:]
            # Equal suffixes choose the first source for deterministic tracing.
            take_first = left_suffix >= right_suffix
        if take_first:
            merged.append(first[i])
            i += 1
        else:
            merged.append(second[j])
            j += 1
    return tuple(merged)


def _solve(first: Sequence[int], second: Sequence[int], requested: int) -> tuple[int, ...]:
    best: tuple[int, ...] | None = None
    minimum_from_first = max(0, requested - len(second))
    maximum_from_first = min(requested, len(first))
    for take_first in range(minimum_from_first, maximum_from_first + 1):
        selected_first = _maximum_subsequence(first, take_first)
        selected_second = _maximum_subsequence(second, requested - take_first)
        candidate = _merge(selected_first, selected_second)
        if best is None or candidate > best:
            best = candidate
    return best if best is not None else ()


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if output_is_null:
        return -2, b""
    first, second, requested = parsed
    if capacity is not None and capacity < requested:
        return -2, b""
    return requested, bytes(_solve(first, second, requested))
