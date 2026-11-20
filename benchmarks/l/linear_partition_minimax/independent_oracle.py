"""Cut-point dynamic-programming reference for linear partition minimax."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALUE,
    MIN_VALUE,
)


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[int, list[int], int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    n, groups = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= groups <= n or len(values) != n + 2:
        return None
    items = list(values[2:])
    if len(items) != n or any(not MIN_VALUE <= item <= MAX_VALUE for item in items):
        return None
    return n, items, groups


def expected_result(values: Sequence[int] | None, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1
    n, items, groups = parsed
    prefix = [0] * (n + 1)
    for i, item in enumerate(items, start=1):
        prefix[i] = prefix[i - 1] + item

    infinity = 1 << 60
    previous = [infinity] * (n + 1)
    previous[0] = 0
    for group_count in range(1, groups + 1):
        current = [infinity] * (n + 1)
        for end in range(group_count, n + 1):
            best = infinity
            for cut in range(group_count - 1, end):
                last_group_sum = prefix[end] - prefix[cut]
                candidate = max(previous[cut], last_group_sum)
                if candidate < best:
                    best = candidate
            current[end] = best
        previous = current
    return previous[n]
