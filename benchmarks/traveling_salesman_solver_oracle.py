"""Bounded scalar projections of the pinned C# TSP solver methods."""

from __future__ import annotations

from itertools import permutations
from collections.abc import Sequence


INVALID_RESULT = -1e300
MAX_CITIES = 8
MAX_EDGE_COST = 1_000
MAX_BRUTE_FORCE_INPUT_LENGTH = 2 + MAX_CITIES * MAX_CITIES
MAX_BRUTE_FORCE_PARSEABLE_INPUT_LENGTH = MAX_BRUTE_FORCE_INPUT_LENGTH + 1
MAX_NEAREST_NEIGHBOR_INPUT_LENGTH = 3 + MAX_CITIES * MAX_CITIES
MAX_NEAREST_NEIGHBOR_PARSEABLE_INPUT_LENGTH = MAX_NEAREST_NEIGHBOR_INPUT_LENGTH + 1


def _parse(values: Sequence[object] | None, *, nearest: bool) -> tuple[int, int, int, list[list[int]]] | None:
    """Parse selector, dimensions, and a bounded row-major distance matrix."""
    if not isinstance(values, (list, tuple)) or any(type(value) is not int for value in values):
        return None
    header = 3 if nearest else 2
    if len(values) < header:
        return None

    selector = values[0]
    city_count = values[1]
    start = values[2] if nearest else 0
    minimum_cities = 1 if nearest else 2
    if not minimum_cities <= city_count <= MAX_CITIES:
        return None
    if not 0 <= selector <= city_count + 1:
        return None
    if nearest and not 0 <= start < city_count:
        return None
    if len(values) != header + city_count * city_count:
        return None

    flat = values[header:]
    if any(cost < 0 or cost > MAX_EDGE_COST for cost in flat):
        return None
    matrix = [list(flat[row * city_count:(row + 1) * city_count])
              for row in range(city_count)]
    return selector, city_count, start, matrix


def expected_result_brute_force(values: Sequence[object] | None) -> float:
    """Return one distance or route-position scalar from SolveBruteForce."""
    parsed = _parse(values, nearest=False)
    if parsed is None:
        return INVALID_RESULT
    selector, city_count, _start, matrix = parsed

    best_distance: int | None = None
    best_route: tuple[int, ...] | None = None
    for order in permutations(range(1, city_count)):
        route = (0, *order, 0)
        distance = sum(matrix[route[index]][route[index + 1]]
                       for index in range(city_count))
        if best_distance is None or distance < best_distance:
            best_distance = distance
            best_route = route

    if selector == 0:
        return float(best_distance) if best_distance is not None else INVALID_RESULT
    if best_route is None:
        return INVALID_RESULT
    return float(best_route[selector - 1])


def expected_result_nearest_neighbor(values: Sequence[object] | None) -> float:
    """Return one distance or route-position scalar from SolveNearestNeighbor."""
    parsed = _parse(values, nearest=True)
    if parsed is None:
        return INVALID_RESULT
    selector, city_count, start, matrix = parsed

    route = [start]
    visited = [False] * city_count
    visited[start] = True
    total_distance = 0
    current = start

    for _ in range(1, city_count):
        minimum_distance = float("inf")
        next_city = -1
        for city in range(city_count):
            if not visited[city] and matrix[current][city] < minimum_distance:
                minimum_distance = matrix[current][city]
                next_city = city
        if next_city == -1:
            return INVALID_RESULT
        route.append(next_city)
        visited[next_city] = True
        total_distance += int(minimum_distance)
        current = next_city

    total_distance += matrix[current][start]
    route.append(start)
    if selector == 0:
        return float(total_distance)
    return float(route[selector - 1])
