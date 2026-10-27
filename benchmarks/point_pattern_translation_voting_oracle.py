"""Bounded clean-room oracle for translation-voting point-pattern matching."""

from __future__ import annotations

import struct
from collections import Counter
from collections.abc import Sequence

MAX_PATTERN_POINTS = 6
MAX_TARGET_POINTS = 8
MAX_COORDINATE = 16
MAX_INPUT_LENGTH = 2 + 2 * (MAX_PATTERN_POINTS + MAX_TARGET_POINTS) + 1
MAX_TRANSLATIONS = MAX_PATTERN_POINTS * MAX_TARGET_POINTS
MAX_OUTPUT_BYTES = 24
MAX_WORKSPACE_BYTES = 2048
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    pattern_count, target_count = values[0], values[1]
    if not 1 <= pattern_count <= MAX_PATTERN_POINTS or not 1 <= target_count <= MAX_TARGET_POINTS:
        return None
    if len(values) != 2 + 2 * (pattern_count + target_count):
        return None
    offset = 2
    pattern = []
    for _ in range(pattern_count):
        point = (values[offset], values[offset + 1])
        offset += 2
        pattern.append(point)
    target = []
    for _ in range(target_count):
        point = (values[offset], values[offset + 1])
        offset += 2
        target.append(point)
    all_points = pattern + target
    if any(abs(coordinate) > MAX_COORDINATE for point in all_points for coordinate in point):
        return None
    if len(set(pattern)) != len(pattern) or len(set(target)) != len(target):
        return None
    return pattern, target


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
    decoded = _decode(values)
    if decoded is None:
        return INVALID_RESULT, b""
    pattern, target = decoded
    votes = Counter((tx - px, ty - py) for px, py in pattern for tx, ty in target)
    # A pair of nonempty finite point sets always contributes at least one vote.
    best_translation = min(votes, key=lambda translation: (-votes[translation], translation[0], translation[1]))
    payload = struct.pack("<qqq", votes[best_translation], *best_translation)
    if output_is_null or capacity is not None and capacity < len(payload):
        return OUTPUT_ERROR, b""
    return len(payload), payload
