"""Slab-and-interval reference for bounded rectangle union area."""

from __future__ import annotations

from collections.abc import Sequence

MAX_RECTANGLES = 64
MIN_COORDINATE = -1_000_000_000
MAX_COORDINATE = 1_000_000_000
MAX_VALID_INPUT_LENGTH = 1 + 4 * MAX_RECTANGLES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_AREA = 4_000_000_000_000_000_000
MAX_WORKSPACE_BYTES = 13_824


def rectangles_from_input(values: Sequence[int], input_is_null: bool = False,
                          input_length: int | None = None) -> list[tuple[int, int, int, int]] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length != len(values)
            or actual_length < 1 or actual_length > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    count = values[0]
    if type(count) is not int or not 0 <= count <= MAX_RECTANGLES:
        return None
    if actual_length != 1 + 4 * count:
        return None
    rectangles: list[tuple[int, int, int, int]] = []
    for offset in range(1, actual_length, 4):
        x1, y1, x2, y2 = values[offset:offset + 4]
        if (not MIN_COORDINATE <= x1 <= MAX_COORDINATE
                or not MIN_COORDINATE <= y1 <= MAX_COORDINATE
                or not MIN_COORDINATE <= x2 <= MAX_COORDINATE
                or not MIN_COORDINATE <= y2 <= MAX_COORDINATE
                or x1 >= x2 or y1 >= y2):
            return None
        rectangles.append((x1, y1, x2, y2))
    return rectangles


def expected_result(values: Sequence[int], input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    rectangles = rectangles_from_input(values, input_is_null, input_length)
    if rectangles is None:
        return -1
    if not rectangles:
        return 0

    x_coordinates = sorted({coordinate for x1, _y1, x2, _y2 in rectangles
                            for coordinate in (x1, x2)})
    area = 0
    for left, right in zip(x_coordinates, x_coordinates[1:]):
        intervals = sorted((y1, y2) for x1, y1, x2, y2 in rectangles
                           if x1 <= left and right <= x2)
        if not intervals:
            continue
        covered_height = 0
        low, high = intervals[0]
        for next_low, next_high in intervals[1:]:
            if next_low > high:
                covered_height += high - low
                low, high = next_low, next_high
            elif next_high > high:
                high = next_high
        covered_height += high - low
        area += (right - left) * covered_height
    return area
