"""Independent event-sweep verifier for online interval coloring output."""

from __future__ import annotations

import struct

MAX_INTERVALS = 64
MAX_INPUT_LENGTH = 1 + 2 * MAX_INTERVALS
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values):
    if (not isinstance(values, (tuple, list)) or not values
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    n = values[0]
    if not 0 <= n <= MAX_INTERVALS or len(values) != 1 + 2 * n:
        return None
    intervals = []
    for pos in range(1, len(values), 2):
        left, right = values[pos:pos + 2]
        if not -1000 <= left <= right <= 1000:
            return None
        intervals.append((left, right))
    return intervals


def _sweep_peak(intervals, levels, current, candidate_level):
    events = {}
    for index, (left, right) in enumerate(intervals[:current + 1]):
        if index != current and levels[index] > candidate_level:
            continue
        starts, ends = events.setdefault(left, [0, 0])
        events[left][0] = starts + 1
        starts, ends = events.setdefault(right, [0, 0])
        events[right][1] = ends + 1
    active = 0
    peak = 0
    for coordinate in sorted(events):
        starts, ends = events[coordinate]
        active += starts  # Closed intervals starting here overlap those ending here.
        peak = max(peak, active)
        active -= ends
    return peak


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                              or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    intervals = _parse(values)
    if intervals is None:
        return -1, b""

    levels = []
    local_colors = []
    colors = []
    for current, (left, right) in enumerate(intervals):
        level = 1
        while _sweep_peak(intervals, levels, current, level) > level:
            level += 1
            if level > current + 1:
                return -1, b""
        levels.append(level)
        used = set()
        for prior in range(current):
            a, b = intervals[prior]
            if levels[prior] == level and a <= right and left <= b:
                used.add(local_colors[prior])
        local = 0
        while local in used and local < 3:
            local += 1
        if local == 3:
            return -1, b""
        local_colors.append(local)
        colors.append(3 * (level - 1) + local)

    output = b"".join(struct.pack("<q", color) for color in colors)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output


def verify_output(values, result: int, output: bytes, input_is_null: bool = False) -> bool:
    if input_is_null or values is None:
        return result == -1 and output == b""
    expected_result, expected = expected_output(values)
    return result == expected_result and output == expected
