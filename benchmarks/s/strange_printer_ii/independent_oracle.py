"""Try every order of target colors and directly simulate their bounding boxes."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import permutations

MAX_ROWS = 6
MAX_COLUMNS = 6
MAX_COLORS = 6
MAX_PARSEABLE_INPUT_LENGTH = 39
INVALID_RESULT = -1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, int, tuple[int, ...]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    rows, columns = values[:2]
    if not 1 <= rows <= MAX_ROWS or not 1 <= columns <= MAX_COLUMNS:
        return None
    if len(values) != 2 + rows * columns:
        return None
    target = tuple(values[2:])
    if any(color < 1 or color > MAX_COLORS for color in target):
        return None
    return rows, columns, target


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    rows, columns, target = parsed
    colors = sorted(set(target))
    boxes: dict[int, tuple[int, int, int, int]] = {}
    for color in colors:
        locations = [(index // columns, index % columns)
                     for index, value in enumerate(target) if value == color]
        boxes[color] = (min(row for row, _ in locations),
                        max(row for row, _ in locations),
                        min(column for _, column in locations),
                        max(column for _, column in locations))

    for order in permutations(colors):
        canvas = [0] * (rows * columns)
        for color in order:
            top, bottom, left, right = boxes[color]
            for row in range(top, bottom + 1):
                for column in range(left, right + 1):
                    canvas[row * columns + column] = color
        if tuple(canvas) == target:
            return 1
    return 0
