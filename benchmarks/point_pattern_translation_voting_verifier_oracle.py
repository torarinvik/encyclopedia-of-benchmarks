"""Independent direct-membership oracle for point-pattern translation votes."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_PATTERN_POINTS = 6
MAX_TARGET_POINTS = 8
MAX_COORDINATE = 16
MAX_INPUT_LENGTH = 2 + 2 * (MAX_PATTERN_POINTS + MAX_TARGET_POINTS) + 1
MAX_OUTPUT_BYTES = 24


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    invalid, output_error = -1, -2
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return invalid, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return invalid, b""
    if (not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return invalid, b""
    pattern_count, target_count = values[0], values[1]
    if (not 1 <= pattern_count <= MAX_PATTERN_POINTS
            or not 1 <= target_count <= MAX_TARGET_POINTS
            or len(values) != 2 + 2 * (pattern_count + target_count)):
        return invalid, b""
    cursor = 2
    pattern = []
    for _ in range(pattern_count):
        pattern.append((values[cursor], values[cursor + 1]))
        cursor += 2
    target = []
    for _ in range(target_count):
        target.append((values[cursor], values[cursor + 1]))
        cursor += 2
    if any(abs(c) > MAX_COORDINATE for p in pattern + target for c in p):
        return invalid, b""
    if len(set(pattern)) != len(pattern) or len(set(target)) != len(target):
        return invalid, b""

    target_members = set(target)
    candidates = {(tx - px, ty - py) for px, py in pattern for tx, ty in target}
    best_count = -1
    best_dx = best_dy = 0
    for dx, dy in candidates:
        count = sum((px + dx, py + dy) in target_members for px, py in pattern)
        if (count > best_count or
                count == best_count and (dx < best_dx or dx == best_dx and dy < best_dy)):
            best_count, best_dx, best_dy = count, dx, dy
    payload = struct.pack("<qqq", best_count, best_dx, best_dy)
    if output_is_null or capacity is not None and capacity < len(payload):
        return output_error, b""
    return len(payload), payload
