"""Independent brute-force oracle for the bounded bitmask TSP contract."""

from __future__ import annotations

from itertools import permutations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_CITIES = 2
MAX_CITIES = 10
MIN_DISTANCE = 0
MAX_DISTANCE = 1_000
MAX_TOUR_COST = 10_000
MAX_VALID_INPUT_LENGTH = 1 + MAX_CITIES * MAX_CITIES
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the shortest closed-tour cost, or the invalid-input sentinel."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) < 1
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT

    city_count = values[0]
    if not MIN_CITIES <= city_count <= MAX_CITIES:
        return INVALID_RESULT
    if len(values) != 1 + city_count * city_count:
        return INVALID_RESULT

    matrix = values[1:]
    for row in range(city_count):
        for column in range(city_count):
            distance = matrix[row * city_count + column]
            if not MIN_DISTANCE <= distance <= MAX_DISTANCE:
                return INVALID_RESULT
            if row == column and distance != 0:
                return INVALID_RESULT

    best = MAX_TOUR_COST + 1
    for order in permutations(range(1, city_count)):
        previous = 0
        cost = 0
        for city in order:
            cost += matrix[previous * city_count + city]
            previous = city
        cost += matrix[previous * city_count]
        if cost < best:
            best = cost
    return best
