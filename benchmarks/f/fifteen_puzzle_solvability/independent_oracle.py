"""Permutation-cycle and blank-color invariant for the 15-puzzle."""

from __future__ import annotations

MAX_INPUT_LENGTH = 16
MAX_PARSEABLE_INPUT_LENGTH = 17
CELL_COUNT = 16


def _parse(values, input_is_null, input_length):
    if input_is_null or not isinstance(values, (tuple, list)):
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
    seen = set()
    blank = -1
    for index, value in enumerate(values):
        if value < 0 or value >= CELL_COUNT or value in seen:
            return None
        seen.add(value)
        if value == 0:
            blank = index
    if len(seen) != CELL_COUNT or blank < 0:
        return None
    return values, blank


def expected_output(values, input_is_null=False, input_length=None):
    """Check equality of full-permutation parity and blank-cell color."""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    cells, blank = parsed

    # Map each tile to its position in the goal permutation [1,...,15,0].
    permutation = [15 if tile == 0 else tile - 1 for tile in cells]
    visited = [False] * CELL_COUNT
    cycle_count = 0
    for start in range(CELL_COUNT):
        if visited[start]:
            continue
        cycle_count += 1
        current = start
        while not visited[current]:
            visited[current] = True
            current = permutation[current]
    permutation_parity = (CELL_COUNT - cycle_count) & 1
    blank_color = ((blank // 4) + (blank % 4)) & 1
    return 1 if permutation_parity == blank_color else 0
