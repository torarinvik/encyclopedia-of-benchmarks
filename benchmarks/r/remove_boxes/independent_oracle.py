"""Independent direct search over legal contiguous equal-color removals."""

from __future__ import annotations

from collections.abc import Sequence
from functools import lru_cache

from .primary_oracle import (
    INVALID_RESULT,
    MAX_BOXES,
    MAX_COLOR,
    MAX_PARSEABLE_INPUT_LENGTH,
)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, ...] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    n = values[0]
    if not 0 <= n <= MAX_BOXES or len(values) != n + 1:
        return None
    colors = tuple(values[1:])
    if any(color < 0 or color > MAX_COLOR for color in colors):
        return None
    return colors


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    colors = _parse(values, input_is_null, input_length)
    if colors is None:
        return INVALID_RESULT

    @lru_cache(maxsize=None)
    def search(remaining: tuple[int, ...]) -> int:
        if not remaining:
            return 0
        best = 0
        start = 0
        while start < len(remaining):
            end = start + 1
            while end < len(remaining) and remaining[end] == remaining[start]:
                end += 1
            # Try every nonempty contiguous sub-run inside this equal-color run.
            for first_removed in range(start, end):
                for after_removed in range(first_removed + 1, end + 1):
                    run_length = after_removed - first_removed
                    next_state = remaining[:first_removed] + remaining[after_removed:]
                    score = run_length * run_length + search(next_state)
                    if score > best:
                        best = score
            start = end
        return best

    return search(colors)


def verify_candidate(values: Sequence[int] | None, result: int,
                     input_is_null: bool = False,
                     input_length: int | None = None) -> bool:
    return (type(result) is int
            and result == expected_result(values, input_is_null, input_length))
