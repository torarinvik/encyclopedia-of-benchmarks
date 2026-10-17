"""Independent bounded oracle for deterministic farthest-first k-centers."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
MAX_POINTS = 8
MAX_DISTANCE = 1_000_000
JAVA_INT_MAX = (1 << 31) - 1
MAX_INPUT_LENGTH = 2 + MAX_POINTS * MAX_POINTS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(
    values: Sequence[int] | None,
    input_length: int | None = None,
) -> int:
    """Return the Java source result, including its one-center sentinel behavior."""
    if values is None:
        return INVALID_RESULT
    if (not isinstance(values, (list, tuple))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or len(values) < 2
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT

    point_count, center_count = values[:2]
    if not 1 <= point_count <= MAX_POINTS or not 1 <= center_count <= point_count:
        return INVALID_RESULT
    if len(values) != 2 + point_count * point_count:
        return INVALID_RESULT
    matrix = [values[2 + row * point_count:2 + (row + 1) * point_count]
              for row in range(point_count)]
    for row in range(point_count):
        for column in range(point_count):
            distance = matrix[row][column]
            if not 0 <= distance <= MAX_DISTANCE:
                return INVALID_RESULT
            if row == column and distance != 0:
                return INVALID_RESULT
            if distance != matrix[column][row]:
                return INVALID_RESULT

    selected = [False] * point_count
    max_distance = [JAVA_INT_MAX] * point_count
    selected[0] = True
    for point in range(1, point_count):
        max_distance[point] = min(max_distance[point], matrix[0][point])

    for _ in range(1, center_count):
        farthest = -1
        for point in range(point_count):
            if not selected[point] and (
                farthest == -1 or max_distance[point] > max_distance[farthest]
            ):
                farthest = point
        selected[farthest] = True
        for point in range(point_count):
            max_distance[point] = min(max_distance[point], matrix[farthest][point])

    return max(max_distance)
