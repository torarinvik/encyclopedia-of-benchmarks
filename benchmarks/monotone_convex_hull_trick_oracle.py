"""Deque lower-hull oracle for the bounded monotone CHT profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_LINES = 32
MAX_QUERIES = 32
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_LINES + MAX_QUERIES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
SLOPE_LIMIT = 1_000
INTERCEPT_LIMIT = 10_000
X_LIMIT = 1_000
INVALID_RESULT = -(1 << 63)
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

SOURCE_BASIS = [
    {
        "organization": "CP-Algorithms",
        "title": "Convex hull trick and Li Chao tree",
        "url": "https://cp-algorithms.com/geometry/convex_hull_trick.html",
        "role": "monotone_slope_algorithm_description",
        "license": "CC BY-SA 4.0",
    }
]


def _crossing_order(first: tuple[int, int], middle: tuple[int, int], last: tuple[int, int]) -> bool:
    """Whether the middle line has no interval on the lower envelope."""
    m1, b1 = first
    m2, b2 = middle
    m3, b3 = last
    return (b2 - b1) * (m2 - m3) >= (b3 - b2) * (m1 - m2)


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Return the weighted minimum checksum, or INT64_MIN for malformed input."""
    if type(input_is_null) is not bool or input_is_null:
        return INVALID_RESULT
    if input_length is not None and (
        type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
    ):
        return INVALID_RESULT
    if not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT

    line_count, query_count = values[0], values[1]
    if not 1 <= line_count <= MAX_LINES or not 0 <= query_count <= MAX_QUERIES:
        return INVALID_RESULT
    if len(values) != 2 + 2 * line_count + query_count:
        return INVALID_RESULT

    lines: list[tuple[int, int]] = []
    cursor = 2
    previous_slope: int | None = None
    for _ in range(line_count):
        slope, intercept = values[cursor], values[cursor + 1]
        cursor += 2
        if not -SLOPE_LIMIT <= slope <= SLOPE_LIMIT:
            return INVALID_RESULT
        if not -INTERCEPT_LIMIT <= intercept <= INTERCEPT_LIMIT:
            return INVALID_RESULT
        if previous_slope is not None and slope >= previous_slope:
            return INVALID_RESULT
        previous_slope = slope
        lines.append((slope, intercept))

    queries = values[cursor:]
    previous_x: int | None = None
    for x in queries:
        if not -X_LIMIT <= x <= X_LIMIT:
            return INVALID_RESULT
        if previous_x is not None and x < previous_x:
            return INVALID_RESULT
        previous_x = x

    hull: list[tuple[int, int]] = []
    front = 0
    for line in lines:
        while len(hull) - front >= 2 and _crossing_order(hull[-2], hull[-1], line):
            hull.pop()
        hull.append(line)

    checksum = 0
    for query_index, x in enumerate(queries, start=1):
        while front + 1 < len(hull):
            first_slope, first_intercept = hull[front]
            next_slope, next_intercept = hull[front + 1]
            if next_slope * x + next_intercept > first_slope * x + first_intercept:
                break
            front += 1
        slope, intercept = hull[front]
        checksum += query_index * (slope * x + intercept)
    if not I64_MIN < checksum <= I64_MAX:
        return INVALID_RESULT
    return checksum
