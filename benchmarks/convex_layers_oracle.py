"""Independent supporting-line oracle for the bounded convex-layer profile."""

from __future__ import annotations

MAX_POINTS = 64
COORD_LIMIT = 1_000_000
MAX_INPUT_LENGTH = 1 + 2 * MAX_POINTS


def _cross(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> int:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _on_supporting_line(point: tuple[int, int], other: tuple[int, int],
                        points: set[tuple[int, int]]) -> bool:
    signs = {_cross(point, other, candidate) for candidate in points}
    return all(value >= 0 for value in signs) or all(value <= 0 for value in signs)


def _boundary(points: set[tuple[int, int]]) -> set[tuple[int, int]]:
    """Find boundary points by exhaustive supporting-line search, not a hull scan."""
    if len(points) <= 2:
        return set(points)
    ordered = sorted(points)
    if all(_cross(ordered[0], ordered[-1], point) == 0 for point in ordered):
        return set(points)
    result: set[tuple[int, int]] = set()
    for point in points:
        for other in points:
            if point != other and _on_supporting_line(point, other, points):
                result.add(point)
                break
    return result


def expected_result(values: list[int] | tuple[int, ...] | None) -> int:
    if values is None or not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return -1
    count = values[0]
    if (type(count) is not int or count < 0 or count > MAX_POINTS
            or len(values) != 1 + 2 * count):
        return -1
    points: set[tuple[int, int]] = set()
    for index in range(count):
        x, y = values[1 + 2 * index], values[2 + 2 * index]
        if (type(x) is not int or type(y) is not int
                or abs(x) > COORD_LIMIT or abs(y) > COORD_LIMIT):
            return -1
        points.add((x, y))

    layers = 0
    while points:
        edge = _boundary(points)
        if not edge:
            return -1
        points.difference_update(edge)
        layers += 1
    return layers
