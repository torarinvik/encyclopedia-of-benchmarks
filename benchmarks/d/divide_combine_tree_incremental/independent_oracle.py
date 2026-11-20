"""Exhaustive connected-interval and overlap oracle, independent of the builder."""

from __future__ import annotations

MAX_N = 16
MAX_PARSEABLE_INPUT_LENGTH = MAX_N + 2
MAX_STRONG_INTERVALS = 2 * MAX_N - 1


def _parse(values, input_is_null=False, input_length=None):
    if input_is_null:
        return None
    try:
        data = tuple(values)
    except TypeError:
        return None
    length = len(data) if input_length is None else input_length
    if (type(length) is not int or length < 1
            or length > MAX_PARSEABLE_INPUT_LENGTH or length != len(data)):
        return None
    if type(data[0]) is not int or not 1 <= data[0] <= MAX_N:
        return None
    n = data[0]
    if length != n + 1:
        return None
    permutation = data[1:]
    if (any(type(value) is not int or not 0 <= value < n
            for value in permutation)
            or len(set(permutation)) != n):
        return None
    return n, permutation


def _strong_intervals(permutation):
    n = len(permutation)
    connected = []
    for left in range(n):
        selected = set()
        for right in range(left, n):
            selected.add(permutation[right])
            if (len(selected) == right - left + 1
                    and max(selected) - min(selected) == right - left):
                connected.append((left, right))

    strong = []
    for left, right in connected:
        overlaps = any(
            (left < other_left <= right < other_right
             or other_left < left <= other_right < right)
            for other_left, other_right in connected
        )
        if not overlaps:
            strong.append((left, right))
    return sorted(strong)


def expected_result(values, input_is_null=False, input_length=None):
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, permutation = parsed
    intervals = _strong_intervals(permutation)
    if len(intervals) > MAX_STRONG_INTERVALS:
        raise AssertionError("exhaustive reference exceeded the strong-interval bound")
    return sum(
        rank * ((left + 1) * (n + 1) + (right + 1))
        for rank, (left, right) in enumerate(intervals, 1)
    )
