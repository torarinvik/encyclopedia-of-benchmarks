"""Independent oracle for the bounded Java brute-force TSP contract."""

from __future__ import annotations

from itertools import permutations

JAVA_INT_MIN = -(1 << 31)
JAVA_INT_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_CITIES = 0
MAX_CITIES = 8
MIN_EDGE_COST = 0
MAX_EDGE_COST = 1_000
MAX_TOUR_COST = 8_000
MAX_VALID_INPUT_LENGTH = 1 + MAX_CITIES * MAX_CITIES
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the Java bruteForce tour cost, or -1 for invalid input."""
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
    if any(not JAVA_INT_MIN <= value <= JAVA_INT_MAX for value in matrix):
        return INVALID_RESULT

    # The pinned Java method returns before inspecting a matrix of size 0 or 1.
    if city_count <= 1:
        return 0

    for row in range(city_count):
        for column in range(city_count):
            if row == column:
                continue
            distance = matrix[row * city_count + column]
            if distance != JAVA_INT_MAX and not MIN_EDGE_COST <= distance <= MAX_EDGE_COST:
                return INVALID_RESULT

    best = JAVA_INT_MAX
    for order in permutations(range(1, city_count)):
        previous = 0
        cost = 0
        valid = True
        for city in order:
            distance = matrix[previous * city_count + city]
            if distance == JAVA_INT_MAX:
                valid = False
                break
            cost += distance
            previous = city
        if not valid:
            continue

        return_distance = matrix[previous * city_count]
        if return_distance == JAVA_INT_MAX:
            continue
        cost += return_distance
        if cost < best:
            best = cost
    return best
