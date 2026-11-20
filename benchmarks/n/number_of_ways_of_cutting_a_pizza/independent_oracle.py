"""First-cut recursion with direct apple counting, independent of suffix DP."""

from __future__ import annotations

from collections.abc import Sequence
from functools import lru_cache

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_COLUMNS,
    MAX_CUTS,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_ROWS,
    MODULUS,
)


def _decode(
    values: Sequence[int] | None,
    input_is_null: bool,
    input_length: int | None,
) -> tuple[int, int, int, list[int]] | None:
    if (
        type(input_is_null) is not bool
        or input_is_null
        or not isinstance(values, (list, tuple))
        or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    rows, columns, cuts = values[:3]
    if not 1 <= rows <= MAX_ROWS or not 1 <= columns <= MAX_COLUMNS:
        return None
    if not 0 <= cuts <= MAX_CUTS or len(values) != 3 + rows * columns:
        return None
    cells = list(values[3:])
    if any(cell not in (0, 1) for cell in cells):
        return None
    return rows, columns, cuts, cells


def expected_output(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    rows, columns, cuts, cells = decoded

    def apple_count(top: int, left: int, bottom: int, right: int) -> int:
        return sum(
            cells[row * columns + column]
            for row in range(top, bottom)
            for column in range(left, right)
        )

    @lru_cache(maxsize=None)
    def count_ways(top: int, left: int, remaining: int) -> int:
        if remaining == 0:
            return int(apple_count(top, left, rows, columns) > 0)
        ways = 0
        for cut_row in range(top + 1, rows):
            if apple_count(top, left, cut_row, columns) > 0:
                ways += count_ways(cut_row, left, remaining - 1)
        for cut_column in range(left + 1, columns):
            if apple_count(top, left, rows, cut_column) > 0:
                ways += count_ways(top, cut_column, remaining - 1)
        return ways % MODULUS

    return count_ways(0, 0, cuts)
