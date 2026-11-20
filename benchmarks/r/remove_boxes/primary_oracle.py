"""Compressed-run, carry-state interval recurrence for remove-boxes scoring."""

from __future__ import annotations

from collections.abc import Sequence
from functools import lru_cache

MAX_BOXES = 18
MAX_INPUT_LENGTH = MAX_BOXES + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_COLOR = 7
MAX_WORKSPACE_BYTES = 65_536
INVALID_RESULT = -1


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


def _compress(colors: tuple[int, ...]) -> tuple[tuple[int, ...], tuple[int, ...]]:
    group_colors: list[int] = []
    group_sizes: list[int] = []
    for color in colors:
        if group_colors and group_colors[-1] == color:
            group_sizes[-1] += 1
        else:
            group_colors.append(color)
            group_sizes.append(1)
    return tuple(group_colors), tuple(group_sizes)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    colors = _parse(values, input_is_null, input_length)
    if colors is None:
        return INVALID_RESULT
    if not colors:
        return 0
    group_colors, group_sizes = _compress(colors)

    @lru_cache(maxsize=None)
    def solve(left: int, right: int, carry: int) -> int:
        if left > right:
            return 0
        attached = group_sizes[left] + carry
        best = attached * attached + solve(left + 1, right, 0)
        for later in range(left + 1, right + 1):
            if group_colors[later] == group_colors[left]:
                joined = (solve(left + 1, later - 1, 0)
                          + solve(later, right, attached))
                best = max(best, joined)
        return best

    return solve(0, len(group_colors) - 1, 0)
