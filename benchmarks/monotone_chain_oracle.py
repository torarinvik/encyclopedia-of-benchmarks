"""Independent bounded oracle for a monotone-chain convex hull."""

from __future__ import annotations

import struct
from collections.abc import Sequence

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_POINT_COUNT = 64
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_POINT_COUNT
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_PARSEABLE_INPUT_VALUES = MAX_INPUT_LENGTH
MAX_COORDINATE = 1_000_000
MAX_OUTPUT_BYTES = 8 * MAX_POINT_COUNT
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def cross(origin: tuple[int, int], first: tuple[int, int], second: tuple[int, int]) -> int:
    return (
        (first[0] - origin[0]) * (second[1] - origin[1])
        - (first[1] - origin[1]) * (second[0] - origin[0])
    )


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return (byte count, convex-hull bytes), or the bounded ABI sentinel."""
    if type(input_is_null) is not bool or type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT, b""

    point_count = values[0]
    if not 0 <= point_count <= MAX_POINT_COUNT or len(values) != 1 + 2 * point_count:
        return INVALID_RESULT, b""
    coordinates = values[1:]
    if any(not -MAX_COORDINATE <= coordinate <= MAX_COORDINATE for coordinate in coordinates):
        return INVALID_RESULT, b""
    if type(output_capacity) is not int or output_capacity < 0:
        return INVALID_RESULT, b""

    points = sorted(set(zip(coordinates[::2], coordinates[1::2])))
    if len(points) <= 1:
        hull = points
    else:
        lower: list[tuple[int, int]] = []
        for point in points:
            while len(lower) >= 2 and cross(lower[-2], lower[-1], point) <= 0:
                lower.pop()
            lower.append(point)

        upper: list[tuple[int, int]] = []
        for point in reversed(points):
            while len(upper) >= 2 and cross(upper[-2], upper[-1], point) <= 0:
                upper.pop()
            upper.append(point)
        hull = lower[:-1] + upper[:-1]

    output = b"".join(struct.pack("<ii", x, y) for x, y in hull)
    if output_is_null or output_capacity < len(output):
        return OUTPUT_ERROR_RESULT, b""
    return len(output), output
