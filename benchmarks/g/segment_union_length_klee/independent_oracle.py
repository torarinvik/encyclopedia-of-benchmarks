"""Coordinate-slab scan independent of the endpoint-event counter sweep."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_N = 64
MAX_PARSEABLE_INPUT_LENGTH = 130


def expected_result(values, input_is_null=False, input_length=None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return -1
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return -1
    if not values:
        return -1
    n = values[0]
    if not 0 <= n <= MAX_N or len(values) != 1 + 2 * n:
        return -1
    intervals = []
    coordinates = set()
    for i in range(n):
        left, right = values[1 + 2 * i: 3 + 2 * i]
        if not -1000 <= left <= right <= 1000:
            return -1
        intervals.append((left, right))
        coordinates.add(left)
        coordinates.add(right)
    ordered = sorted(coordinates)
    total = 0
    for low, high in zip(ordered, ordered[1:]):
        if any(left <= low and right >= high for left, right in intervals):
            total += high - low
    return total
