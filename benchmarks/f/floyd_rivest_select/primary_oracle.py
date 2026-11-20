"""Bounded Floyd–Rivest rank-centered selection reference."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_ITEMS = 1
MAX_ITEMS = 64
SAMPLE_THRESHOLD = 24
MIN_VALUE = 0
MAX_VALUE = (1 << 31) - 1
MAX_VALID_INPUT_LENGTH = MAX_ITEMS + 2
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = MAX_VALUE


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> list[int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    count, rank = values[:2]
    if (not MIN_ITEMS <= count <= MAX_ITEMS
            or not 0 <= rank < count
            or len(values) != count + 2):
        return None
    items = list(values[2:])
    if (any(not MIN_VALUE <= value <= MAX_VALUE for value in items)
            or len(set(items)) != count):
        return None
    return items


def _select(items: list[int], left: int, right: int, target: int) -> int:
    while True:
        if right - left > SAMPLE_THRESHOLD:
            size = right - left + 1
            relative_rank = target - left + 1
            z = math.sqrt(math.log(size))
            sample_size = 0.5 * math.exp(2.0 * z / 3.0)
            if relative_rank < size / 2.0:
                direction = -1.0
            elif relative_rank > size / 2.0:
                direction = 1.0
            else:
                direction = 0.0
            spread = 0.5 * math.sqrt(
                z * sample_size * (size - sample_size) / size
            ) * direction
            lower_estimate = target - relative_rank * sample_size / size + spread
            upper_estimate = target + (size - relative_rank) * sample_size / size + spread
            sample_left = max(left, target, math.floor(lower_estimate))
            sample_right = min(right, target, math.ceil(upper_estimate))
            _select(items, sample_left, sample_right, target)

        pivot = items[target]
        less = left
        scan = left
        greater = right
        while scan <= greater:
            if items[scan] < pivot:
                items[less], items[scan] = items[scan], items[less]
                less += 1
                scan += 1
            elif items[scan] > pivot:
                items[scan], items[greater] = items[greater], items[scan]
                greater -= 1
            else:
                scan += 1
        if target < less:
            right = less - 1
        elif target > greater:
            left = greater + 1
        else:
            return pivot


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    target = values[1]  # type: ignore[index]
    return _select(parsed, 0, len(parsed) - 1, target)
