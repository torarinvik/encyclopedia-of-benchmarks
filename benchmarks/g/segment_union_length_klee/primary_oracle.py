"""Klee endpoint-event sweep for the measure of a union of intervals."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_N = 64
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1


def _decode(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if not values:
        return None
    n = values[0]
    if not 0 <= n <= MAX_N or len(values) != 1 + 2 * n:
        return None
    intervals = []
    for i in range(n):
        left, right = values[1 + 2 * i: 3 + 2 * i]
        if not -1000 <= left <= right <= 1000:
            return None
        intervals.append((left, right))
    return intervals


def expected_result(values, input_is_null=False, input_length=None) -> int:
    intervals = _decode(values, input_is_null, input_length)
    if intervals is None:
        return -1
    events = []
    for left, right in intervals:
        events.append((left, 1))
        events.append((right, -1))
    events.sort()
    covered = 0
    total = 0
    previous = None
    index = 0
    while index < len(events):
        coordinate = events[index][0]
        if previous is not None and covered > 0:
            total += coordinate - previous
        delta = 0
        while index < len(events) and events[index][0] == coordinate:
            delta += events[index][1]
            index += 1
        covered += delta
        previous = coordinate
    return total
