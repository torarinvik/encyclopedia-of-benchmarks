"""Inversion-and-blank-row parity oracle for the 15-puzzle."""

from __future__ import annotations

MAX_INPUT_LENGTH = 16
MAX_PARSEABLE_INPUT_LENGTH = 17
CELL_COUNT = 16


def _parse(values, input_is_null, input_length):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if len(values) < CELL_COUNT or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    if len(values) != CELL_COUNT:
        return None
    seen = 0
    blank = -1
    for index, value in enumerate(values):
        if not 0 <= value < CELL_COUNT or seen & (1 << value):
            return None
        seen |= 1 << value
        if value == 0:
            blank = index
    if seen != (1 << CELL_COUNT) - 1 or blank < 0:
        return None
    return values, blank


def expected_output(values, input_is_null=False, input_length=None):
    """Return 1 when solvable, 0 when parity-incompatible, or -1 if invalid."""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    cells, blank = parsed
    inversions = 0
    for left in range(CELL_COUNT):
        if cells[left] == 0:
            continue
        for right in range(left + 1, CELL_COUNT):
            if cells[right] != 0 and cells[left] > cells[right]:
                inversions += 1
    blank_row_from_top = blank // 4 + 1
    return 1 if (inversions + blank_row_from_top) % 2 == 0 else 0
