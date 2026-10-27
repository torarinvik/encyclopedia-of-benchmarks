"""Bounded clean-room oracle for exact translation matching by forward scan."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_PATTERN_POINTS = 6
MAX_TARGET_POINTS = 8
MAX_COORDINATE = 16
MAX_INPUT_LENGTH = 31
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
    if (not 1 <= pattern_count <= MAX_PATTERN_POINTS
            or not 1 <= target_count <= MAX_TARGET_POINTS or pattern_count > target_count):
        return None
    if len(values) != 2 + 2 * (pattern_count + target_count):
        return None
    cursor = 2
    pattern = []
    for _ in range(pattern_count):
        pattern.append((values[cursor], values[cursor + 1]))
        cursor += 2
    target = []
    for _ in range(target_count):
        target.append((values[cursor], values[cursor + 1]))
        cursor += 2
    if any(abs(coord) > MAX_COORDINATE for point in pattern + target for coord in point):
        return None
    if any(pattern[i - 1] >= pattern[i] for i in range(1, len(pattern))):
        return None
    if any(target[i - 1] >= target[i] for i in range(1, len(target))):
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

    found, dx, dy = 0, 0, 0
    for target_index, (anchor_x, anchor_y) in enumerate(target):
        candidate_x = anchor_x - pattern[0][0]
        candidate_y = anchor_y - pattern[0][1]
        scan_index = target_index + 1
        # This oracle follows the chapter's successive forward target scan.
        matches = True
        for point_x, point_y in pattern[1:]:
            wanted = (point_x + candidate_x, point_y + candidate_y)
            while scan_index < len(target) and target[scan_index] < wanted:
                scan_index += 1
            if scan_index == len(target) or target[scan_index] != wanted:
                matches = False
                break
            scan_index += 1
        if matches:
            found, dx, dy = 1, candidate_x, candidate_y
            break

    payload = struct.pack("<qqq", found, dx, dy)
    if output_is_null or capacity is not None and capacity < len(payload):
        return OUTPUT_ERROR, b""
    return len(payload), payload
