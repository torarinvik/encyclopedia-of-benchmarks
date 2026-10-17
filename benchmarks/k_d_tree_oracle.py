"""Independent oracle for the bounded Lua k-d tree nearest-neighbor query."""

from __future__ import annotations

import math

MAX_INPUT_LENGTH = 51
MAX_OUTPUT_ELEMENTS = 4
MAX_VALID_INPUT_LENGTH = 50
MIN_DIMENSION = 2
MAX_DIMENSION = 3
MIN_POINT_COUNT = 1
MAX_POINT_COUNT = 15
MIN_COORDINATE = -1000
MAX_COORDINATE = 1000
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _integer(value: object) -> int | None:
    if type(value) not in (int, float):
        return None
    try:
        number = float(value)
    except (OverflowError, TypeError, ValueError):
        return None
    if not math.isfinite(number) or not number.is_integer():
        return None
    return int(number)


def expected_output(values: list[int | float] | tuple[int | float, ...]) -> list[float] | None:
    """Return [Euclidean distance, nearest point...] or None for invalid input."""
    if not isinstance(values, (list, tuple)) or not values or len(values) > MAX_INPUT_LENGTH:
        return None
    for value in values:
        if type(value) not in (int, float):
            return None
        try:
            if not math.isfinite(float(value)):
                return None
        except (OverflowError, TypeError, ValueError):
            return None
    dimension = _integer(values[0])
    point_count = _integer(values[1]) if len(values) >= 2 else None
    if dimension not in (2, 3) or point_count is None or not 1 <= point_count <= MAX_POINT_COUNT:
        return None
    if len(values) != 2 + dimension * (point_count + 1):
        return None

    query: list[int] = []
    for value in values[2:2 + dimension]:
        coordinate = _integer(value)
        if coordinate is None or not MIN_COORDINATE <= coordinate <= MAX_COORDINATE:
            return None
        query.append(coordinate)

    points: list[tuple[int, ...]] = []
    offset = 2 + dimension
    for point_index in range(point_count):
        point: list[int] = []
        for axis in range(dimension):
            coordinate = _integer(values[offset + point_index * dimension + axis])
            if coordinate is None or not MIN_COORDINATE <= coordinate <= MAX_COORDINATE:
                return None
            point.append(coordinate)
        points.append(tuple(point))

    for axis in range(dimension):
        coordinates = [point[axis] for point in points]
        if len(set(coordinates)) != point_count:
            return None

    distances_squared = [sum((query[axis] - point[axis]) ** 2 for axis in range(dimension))
                         for point in points]
    smallest = min(distances_squared)
    if sum(distance == smallest for distance in distances_squared) != 1:
        return None

    # The pinned default builder chooses the ceil(n/2)-th value using strict
    # axis comparison. Per-axis uniqueness makes sorted selection equivalent.
    def build(items: list[tuple[int, ...]], depth: int):
        if not items:
            return None
        axis = depth % dimension
        ordered = sorted(items, key=lambda point: point[axis])
        middle = (len(ordered) - 1) // 2
        return (ordered[middle],
                build(ordered[:middle], depth + 1),
                build(ordered[middle + 1:], depth + 1),
                axis)

    best_distance = math.inf
    best_point: tuple[int, ...] | None = None

    def search(node, axis: int) -> None:
        nonlocal best_distance, best_point
        if node is None:
            return
        point, left, right, split_axis = node
        distance = math.sqrt(sum((query[index] - point[index]) ** 2
                                 for index in range(dimension)))
        if distance < best_distance:
            best_distance, best_point = distance, point
        go_left = query[axis] <= point[axis]
        near, far = (left, right) if go_left else (right, left)
        next_axis = (axis + 1) % dimension
        search(near, next_axis)
        if best_distance >= abs(point[axis] - query[axis]):
            search(far, next_axis)

    search(build(points, 0), 0)
    assert best_point is not None
    return [best_distance, *(float(coordinate) for coordinate in best_point)]
