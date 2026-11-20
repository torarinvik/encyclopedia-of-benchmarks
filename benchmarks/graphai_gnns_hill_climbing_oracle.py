"""Primary mask-based oracle for a bounded GNNS hill-climbing profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 16
MAX_DIMENSIONS = 4
MAX_EXPANSIONS = 15
MAX_STEPS = 16
COORDINATE_LIMIT = 100
MAX_DISTANCE = MAX_DIMENSIONS * (2 * COORDINATE_LIMIT) ** 2
MAX_VALID_INPUT_LENGTH = 5 + MAX_VERTICES * MAX_DIMENSIONS + MAX_VERTICES + MAX_DIMENSIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    length = len(values) if input_length is None else input_length
    if (type(length) is not int or length < 5 or length > MAX_PARSEABLE_INPUT_LENGTH
            or length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, dimension, start, expansions, steps = values[:5]
    if not 2 <= n <= MAX_VERTICES or not 1 <= dimension <= MAX_DIMENSIONS:
        return None
    if not 0 <= start < n or not 1 <= expansions <= n - 1 or not 0 <= steps <= MAX_STEPS:
        return None
    if length != 5 + n * dimension + n + dimension:
        return None
    cursor = 5
    points: list[list[int]] = []
    for _vertex in range(n):
        point = list(values[cursor:cursor + dimension])
        if any(not -COORDINATE_LIMIT <= coordinate <= COORDINATE_LIMIT for coordinate in point):
            return None
        points.append(point)
        cursor += dimension
    masks = list(values[cursor:cursor + n])
    cursor += n
    valid_bits = (1 << n) - 1
    for vertex, mask in enumerate(masks):
        if mask < 0 or mask & ~valid_bits or mask & (1 << vertex):
            return None
    query = list(values[cursor:cursor + dimension])
    if any(not -COORDINATE_LIMIT <= coordinate <= COORDINATE_LIMIT for coordinate in query):
        return None
    return n, dimension, start, expansions, steps, points, masks, query


def _distance(point: Sequence[int], query: Sequence[int]) -> int:
    return sum((coordinate - target) ** 2 for coordinate, target in zip(point, query))


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, _dimension, current, expansions, steps, points, masks, query = parsed
    current_distance = _distance(points[current], query)
    evaluations = 1
    moves = 0
    for _step in range(steps):
        best_vertex = current
        best_distance = current_distance
        inspected = 0
        for vertex in range(n):
            if masks[current] & (1 << vertex):
                distance = _distance(points[vertex], query)
                evaluations += 1
                inspected += 1
                if (distance, vertex) < (best_distance, best_vertex):
                    best_vertex, best_distance = vertex, distance
                if inspected == expansions:
                    break
        if best_distance >= current_distance:
            break
        current, current_distance = best_vertex, best_distance
        moves += 1
    return (((evaluations * 17 + moves) * 16 + current) * (MAX_DISTANCE + 1)
            + current_distance)
