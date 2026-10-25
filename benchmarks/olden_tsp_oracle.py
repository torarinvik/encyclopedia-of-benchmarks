"""Independent oracle for Olden's bounded conquer-and-merge TSP kernel."""

from __future__ import annotations

from math import floor, sqrt

ALLOWED_CITIES = (3, 7)
MAX_INPUT_LENGTH = 15
SCALE = 1_000
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1


def _distance(x: list[int], y: list[int], a: int, b: int) -> float:
    dx, dy = x[a] - x[b], y[a] - y[b]
    return sqrt(float(dx * dx + dy * dy))


def _subtree_size(node: int, count: int) -> int:
    if node >= count:
        return 0
    return 1 + _subtree_size(2 * node + 1, count) + _subtree_size(2 * node + 2, count)


def _postorder(node: int, count: int, output: list[int]) -> None:
    if node >= count:
        return
    _postorder(2 * node + 1, count, output)
    _postorder(2 * node + 2, count, output)
    output.append(node)


def _reverse(start: int, size: int, next_node: list[int], prev_node: list[int]) -> None:
    current = start
    for _ in range(size):
        old_next = next_node[current]
        next_node[current], prev_node[current] = prev_node[current], old_next
        current = old_next


def _conquer(order: list[int], x: list[int], y: list[int], next_node: list[int], prev_node: list[int]) -> int:
    cycle = order[0]
    next_node[cycle] = prev_node[cycle] = cycle
    for point in order[1:]:
        nearest = cycle
        nearest_distance = _distance(x, y, point, cycle)
        current = next_node[cycle]
        while current != cycle:
            test = _distance(x, y, point, current)
            if test < nearest_distance:
                nearest_distance = test
                nearest = current
            current = next_node[current]
        next_city, prev_city = next_node[nearest], prev_node[nearest]
        min_to_next = _distance(x, y, nearest, next_city)
        min_to_prev = _distance(x, y, nearest, prev_city)
        point_to_next = _distance(x, y, point, next_city)
        point_to_prev = _distance(x, y, point, prev_city)
        if point_to_prev - min_to_prev < point_to_next - min_to_next:
            next_node[prev_city] = point
            prev_node[point] = prev_city
            next_node[point] = nearest
            prev_node[nearest] = point
        else:
            prev_node[next_city] = point
            next_node[point] = next_city
            next_node[nearest] = point
            prev_node[point] = nearest
    return cycle


def _merge(a: int, b: int, point: int, size_a: int, size_b: int,
           x: list[int], y: list[int], next_node: list[int], prev_node: list[int]) -> int:
    nearest = a
    nearest_distance = _distance(x, y, point, a)
    current = next_node[a]
    while current != a:
        test = _distance(x, y, point, current)
        if test < nearest_distance:
            nearest_distance = test
            nearest = current
        current = next_node[current]
    next_city, prev_city = next_node[nearest], prev_node[nearest]
    min_to_next = _distance(x, y, nearest, next_city)
    min_to_prev = _distance(x, y, nearest, prev_city)
    point_to_next = _distance(x, y, point, next_city)
    point_to_prev = _distance(x, y, point, prev_city)
    if point_to_prev - min_to_prev < point_to_next - min_to_next:
        p1, n1 = prev_city, nearest
        tton1, ttop1 = nearest_distance, point_to_prev
    else:
        p1, n1 = nearest, next_city
        ttop1, tton1 = nearest_distance, point_to_next

    nearest = b
    nearest_distance = _distance(x, y, point, b)
    current = next_node[b]
    while current != b:
        test = _distance(x, y, point, current)
        if test < nearest_distance:
            nearest_distance = test
            nearest = current
        current = next_node[current]
    next_city, prev_city = next_node[nearest], prev_node[nearest]
    min_to_next = _distance(x, y, nearest, next_city)
    min_to_prev = _distance(x, y, nearest, prev_city)
    point_to_next = _distance(x, y, point, next_city)
    point_to_prev = _distance(x, y, point, prev_city)
    if point_to_prev - min_to_prev < point_to_next - min_to_next:
        p2, n2 = prev_city, nearest
        tton2, ttop2 = nearest_distance, point_to_prev
    else:
        p2, n2 = nearest, next_city
        ttop2, tton2 = nearest_distance, point_to_next

    n1_to_n2 = _distance(x, y, n1, n2)
    n1_to_p2 = _distance(x, y, n1, p2)
    p1_to_n2 = _distance(x, y, p1, n2)
    p1_to_p2 = _distance(x, y, p1, p2)
    best = ttop1 + ttop2 + n1_to_n2
    choice = 1
    test = ttop1 + tton2 + n1_to_p2
    if test < best:
        choice, best = 2, test
    test = tton1 + ttop2 + p1_to_n2
    if test < best:
        choice, best = 3, test
    if tton1 + tton2 + p1_to_p2 < best:
        choice = 4

    if choice == 1:
        _reverse(n2, size_b, next_node, prev_node)
        next_node[p1] = point
        prev_node[point] = p1
        next_node[point] = p2
        prev_node[p2] = point
        next_node[n2] = n1
        prev_node[n1] = n2
    elif choice == 2:
        next_node[p1] = point
        prev_node[point] = p1
        next_node[point] = n2
        prev_node[n2] = point
        next_node[p2] = n1
        prev_node[n1] = p2
    elif choice == 3:
        next_node[p2] = point
        prev_node[point] = p2
        next_node[point] = n1
        prev_node[n1] = point
        next_node[p1] = n2
        prev_node[n2] = p1
    else:
        _reverse(n1, size_a, next_node, prev_node)
        next_node[n1] = point
        prev_node[point] = n1
        next_node[point] = n2
        prev_node[n2] = point
        next_node[p2] = p1
        prev_node[p1] = p2
    return point


def _solve(node: int, count: int, x: list[int], y: list[int],
           next_node: list[int], prev_node: list[int]) -> int:
    size = _subtree_size(node, count)
    if size <= 3:
        order: list[int] = []
        _postorder(node, count, order)
        return _conquer(order, x, y, next_node, prev_node)
    left, right = 2 * node + 1, 2 * node + 2
    left_cycle = _solve(left, count, x, y, next_node, prev_node)
    right_cycle = _solve(right, count, x, y, next_node, prev_node)
    return _merge(left_cycle, right_cycle, node, _subtree_size(left, count),
                  _subtree_size(right, count), x, y, next_node, prev_node)


def expected_result(values: list[int] | tuple[int, ...] | None) -> int:
    if not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT
    count = values[0]
    if count not in ALLOWED_CITIES or len(values) != 1 + 2 * count:
        return INVALID_RESULT
    coords = values[1:]
    if any(value < -8 or value > 8 for value in coords):
        return INVALID_RESULT
    x = [coords[2 * city] for city in range(count)]
    y = [coords[2 * city + 1] for city in range(count)]
    next_node = [0] * count
    prev_node = [0] * count
    _solve(0, count, x, y, next_node, prev_node)
    tour_length = 0.0
    city = 0
    for _ in range(count):
        following = next_node[city]
        tour_length += _distance(x, y, city, following)
        city = following
    return floor(tour_length * SCALE + 0.5)
