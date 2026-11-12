"""Independent skip/take dynamic program for the best output digit sequence."""

from __future__ import annotations

from collections.abc import Sequence
from functools import lru_cache

MAX_SOURCE_LENGTH = 6
MAX_PARSEABLE_LENGTH = 16


def _parse(
    values: Sequence[int] | None,
    input_is_null: bool,
    input_length: int | None,
) -> tuple[tuple[int, ...], tuple[int, ...], int] | None:
    if input_is_null or not isinstance(values, (list, tuple)) or len(values) < 3 or len(values) > MAX_PARSEABLE_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    for value in values:
        if type(value) is not int or value < -(1 << 63) or value >= (1 << 63):
            return None
    m, n, k = values[0], values[1], values[2]
    if m < 0 or m > MAX_SOURCE_LENGTH or n < 0 or n > MAX_SOURCE_LENGTH:
        return None
    if k < 0 or k > m + n or len(values) != 3 + m + n:
        return None
    a = tuple(values[3 : 3 + m])
    b = tuple(values[3 + m :])
    if any(digit < 0 or digit > 9 for digit in a + b):
        return None
    return a, b, k


def _best_sequence(first: Sequence[int], second: Sequence[int], requested: int) -> tuple[int, ...]:
    @lru_cache(maxsize=None)
    def choose(i: int, j: int, remaining: int) -> tuple[int, ...] | None:
        if remaining == 0:
            return ()
        if len(first) - i + len(second) - j < remaining:
            return None

        candidates: list[tuple[int, ...]] = []
        if i < len(first):
            skipped = choose(i + 1, j, remaining)
            if skipped is not None:
                candidates.append(skipped)
            tail = choose(i + 1, j, remaining - 1)
            if tail is not None:
                candidates.append((first[i],) + tail)
        if j < len(second):
            skipped = choose(i, j + 1, remaining)
            if skipped is not None:
                candidates.append(skipped)
            tail = choose(i, j + 1, remaining - 1)
            if tail is not None:
                candidates.append((second[j],) + tail)
        return max(candidates) if candidates else None

    answer = choose(0, 0, requested)
    return answer if answer is not None else ()


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
    return requested, bytes(_best_sequence(first, second, requested))
