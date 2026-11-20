"""Independent adjacency-list oracle for the bounded GNNS profile."""

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


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None):
    if input_is_null or not isinstance(values, (tuple, list)):
        return None
    declared = len(values) if input_length is None else input_length
    if type(declared) is not int or declared != len(values) or not 5 <= declared <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    size, dimensions, first, effort, budget = values[:5]
    if not (2 <= size <= MAX_VERTICES and 1 <= dimensions <= MAX_DIMENSIONS
            and 0 <= first < size and 1 <= effort < size and 0 <= budget <= MAX_STEPS):
        return None
    if declared != 5 + size * dimensions + size + dimensions:
        return None
    offset = 5
    coordinates = []
    for _ in range(size):
        coordinates.append(tuple(values[offset:offset + dimensions]))
        offset += dimensions
    encoded = values[offset:offset + size]
    offset += size
    query = tuple(values[offset:offset + dimensions])
    if any(abs(x) > COORDINATE_LIMIT for point in coordinates for x in point):
        return None
    if any(abs(x) > COORDINATE_LIMIT for x in query):
        return None
    adjacency = []
    for source, mask in enumerate(encoded):
        if mask < 0 or mask >> size or mask & (1 << source):
            return None
        adjacency.append([target for target in range(size) if mask & (1 << target)])
    return size, first, effort, budget, coordinates, adjacency, query


def _squared_distance(point: Sequence[int], query: Sequence[int]) -> int:
    result = 0
    for axis in range(len(query)):
        delta = point[axis] - query[axis]
        result += delta * delta
    return result


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    size, current, effort, budget, coordinates, adjacency, query = decoded
    distance = _squared_distance(coordinates[current], query)
    calls, moves = 1, 0
    for _ in range(budget):
        examined = [(_squared_distance(coordinates[node], query), node)
                    for node in adjacency[current][:effort]]
        calls += len(examined)
        if not examined:
            break
        candidate_distance, candidate = min(examined)
        if candidate_distance >= distance:
            break
        current, distance = candidate, candidate_distance
        moves += 1
    return (((calls * 17 + moves) * 16 + current) * (MAX_DISTANCE + 1) + distance)
