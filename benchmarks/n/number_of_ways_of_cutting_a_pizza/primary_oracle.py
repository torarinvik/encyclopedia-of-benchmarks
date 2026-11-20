"""Suffix-count dynamic program for bounded guillotine pizza cuts."""

from __future__ import annotations

from collections.abc import Sequence

MODULUS = 1_000_000_007
MAX_ROWS = 6
MAX_COLUMNS = 6
MAX_CUTS = 5
MAX_VALID_INPUT_LENGTH = 39
MAX_PARSEABLE_INPUT_LENGTH = 39
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
OFFICIAL_SOURCE_URL = "https://leetcode.com/problems/number-of-ways-of-cutting-a-pizza/"


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
    stride = columns + 1
    suffix = [0] * ((rows + 1) * stride)
    for row in range(rows - 1, -1, -1):
        for column in range(columns - 1, -1, -1):
            suffix[row * stride + column] = (
                cells[row * columns + column]
                + suffix[(row + 1) * stride + column]
                + suffix[row * stride + column + 1]
                - suffix[(row + 1) * stride + column + 1]
            )

    previous = [0] * ((rows + 1) * stride)
    for row in range(rows):
        for column in range(columns):
            previous[row * stride + column] = int(suffix[row * stride + column] > 0)

    for _remaining in range(1, cuts + 1):
        current = [0] * len(previous)
        for row in range(rows - 1, -1, -1):
            for column in range(columns - 1, -1, -1):
                origin = row * stride + column
                ways = 0
                for cut_row in range(row + 1, rows):
                    if suffix[origin] - suffix[cut_row * stride + column] > 0:
                        ways += previous[cut_row * stride + column]
                for cut_column in range(column + 1, columns):
                    if suffix[origin] - suffix[row * stride + cut_column] > 0:
                        ways += previous[row * stride + cut_column]
                current[origin] = ways % MODULUS
        previous = current
    return previous[0]
