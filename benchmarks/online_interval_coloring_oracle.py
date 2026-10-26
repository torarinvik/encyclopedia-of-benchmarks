"""Exact oracle for the bounded level-based online interval coloring profile."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_INTERVALS = 64
MAX_INPUT_LENGTH = 1 + 2 * MAX_INTERVALS
MAX_OUTPUT_BYTES = 8 * MAX_INTERVALS
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 1
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    count = values[0]
    if not 0 <= count <= MAX_INTERVALS or len(values) != 1 + 2 * count:
        return None
    intervals = []
    for offset in range(1, len(values), 2):
        left, right = values[offset:offset + 2]
        if not -1000 <= left <= 1000 or not -1000 <= right <= 1000 or left > right:
            return None
        intervals.append((left, right))
    return intervals


def _color(intervals: list[tuple[int, int]]) -> list[int]:
    """Apply the arrival-order level rule, testing each interval-start coordinate."""
    levels: list[int] = []
    within_level: list[int] = []
    result: list[int] = []
    for current, (left, right) in enumerate(intervals):
        for level in range(1, current + 2):
            peak = 0
            for point, _ in intervals[:current + 1]:
                overlap = sum(
                    1 for index, (a, b) in enumerate(intervals[:current + 1])
                    if (index == current or levels[index] <= level) and a <= point <= b
                )
                peak = max(peak, overlap)
            if peak <= level:
                chosen_level = level
                break
        else:  # The new singleton level always fits for a finite prefix.
            raise AssertionError("bounded interval prefix has no admissible level")
        levels.append(chosen_level)
        forbidden = {
            within_level[index]
            for index in range(current)
            if levels[index] == chosen_level
            and intervals[index][0] <= right and left <= intervals[index][1]
        }
        local = next(color for color in range(3) if color not in forbidden)
        within_level.append(local)
        result.append(3 * (chosen_level - 1) + local)
    return result


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    intervals = _parse(values)
    if intervals is None:
        return INVALID_RESULT, b""
    output = b"".join(struct.pack("<q", color) for color in _color(intervals))
    if output_is_null or capacity is not None and capacity < len(output):
        return OUTPUT_ERROR, b""
    return len(output), output
