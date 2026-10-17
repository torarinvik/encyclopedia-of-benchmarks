"""Bounded oracle for the pinned Java divide-and-conquer skyline algorithm."""

from __future__ import annotations

import struct

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
MIN_POINT_COUNT = 1
MAX_POINT_COUNT = 64
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_POINT_COUNT
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 1 + 8 * MAX_POINT_COUNT
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _parse_input(
        values: tuple[int, ...] | list[int],
        input_is_null: bool,
        input_length: int,
) -> list[tuple[int, int]] | None:
    if (not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or type(input_is_null) is not bool
            or input_is_null
            or type(input_length) is not int
            or not 1 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None

    count = values[0]
    if not MIN_POINT_COUNT <= count <= MAX_POINT_COUNT or input_length != 1 + 2 * count:
        return None
    points: list[tuple[int, int]] = []
    previous_x: int | None = None
    for index in range(count):
        x = values[1 + 2 * index]
        y = values[2 + 2 * index]
        if (not I32_MIN <= x <= I32_MAX or not 1 <= y <= I32_MAX
                or previous_x is not None and x <= previous_x):
            return None
        points.append((x, y))
        previous_x = x
    return points


def _dominates(left: tuple[int, int], right: tuple[int, int]) -> bool:
    return ((left[0] < right[0] and left[1] <= right[1])
            or (left[0] <= right[0] and left[1] < right[1]))


def _merge(left: list[tuple[int, int]], right: list[tuple[int, int]]) -> list[tuple[int, int]]:
    index = 0
    while index < len(left) - 1:
        if left[index][0] == left[index + 1][0] and left[index][1] > left[index + 1][1]:
            left.pop(index)
            index -= 1
        index += 1

    minimum_y = left[0][1]
    index = 1
    while index < len(left):
        if minimum_y > left[index][1]:
            minimum_y = left[index][1]
            if minimum_y == 1:
                index = len(left)
        index += 1

    index = 0
    while index < len(right):
        if right[index][1] >= minimum_y:
            right.pop(index)
            index -= 1
        index += 1
    return left + right


def _produce(points: list[tuple[int, int]]) -> list[tuple[int, int]]:
    size = len(points)
    if size == 1:
        return points
    if size == 2:
        if _dominates(points[0], points[1]):
            points.pop(1)
        elif _dominates(points[1], points[0]):
            points.pop(0)
        return points
    middle = size // 2
    left = _produce(points[:middle])
    right = _produce(points[middle:])
    return _merge(left, right)


def _serialize(points: list[tuple[int, int]]) -> bytes:
    output = bytearray((len(points),))
    for x, y in points:
        output.extend(struct.pack("<i", x))
        output.extend(struct.pack("<i", y))
    return bytes(output)


def _compute(points: list[tuple[int, int]]) -> tuple[int, bytes]:
    output = _serialize(_produce(points))
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    return len(output), output


def expected_result(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Return result byte count and source-order skyline for valid input framing."""
    input_length = len(values) if isinstance(values, (tuple, list)) else -1
    points = _parse_input(values, False, input_length)
    if points is None:
        return INVALID_RESULT, b""
    return _compute(points)


def expected_output(
        values: tuple[int, ...] | list[int],
        capacity: int = MAX_OUTPUT_BYTES,
        output_is_null: bool = False,
        input_is_null: bool = False,
        input_length: int | None = None,
) -> tuple[int, bytes]:
    """Model bounded input checks, output pointer, and byte capacity."""
    effective_length = (len(values) if input_length is None
                        and isinstance(values, (tuple, list)) else input_length)
    if effective_length is None:
        return INVALID_RESULT, b""
    points = _parse_input(values, input_is_null, effective_length)
    if points is None:
        return INVALID_RESULT, b""
    result, output = _compute(points)
    if (type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_BYTES
            or type(output_is_null) is not bool):
        return INVALID_RESULT, b""
    if output_is_null or capacity < result:
        return OUTPUT_ERROR, b""
    return result, output
