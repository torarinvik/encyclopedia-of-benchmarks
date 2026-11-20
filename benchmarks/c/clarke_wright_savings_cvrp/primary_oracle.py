"""Primary route-chain reference for parallel Clarke–Wright savings."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_CUSTOMERS = 7
MAX_CAPACITY = 100
MAX_DISTANCE = 1000
MAX_VALID_INPUT_LENGTH = 2 + MAX_CUSTOMERS + (MAX_CUSTOMERS + 1) ** 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 120
_I64_MIN = -(1 << 63)
_I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not _I64_MIN <= value <= _I64_MAX
                   for value in values)):
        return None
    n, capacity = values[0], values[1]
    if not 0 <= n <= MAX_CUSTOMERS or not 1 <= capacity <= MAX_CAPACITY:
        return None
    expected_length = 2 + n + (n + 1) ** 2
    if len(values) != expected_length:
        return None
    demands = [0] + list(values[2:2 + n])
    if any(not 1 <= demand <= capacity for demand in demands[1:]):
        return None
    matrix_values = values[2 + n:]
    width = n + 1
    distances = [list(matrix_values[row * width:(row + 1) * width])
                 for row in range(width)]
    if any(type(distance) is not int or not 0 <= distance <= MAX_DISTANCE
           for row in distances for distance in row):
        return None
    if any(distances[i][i] != 0 for i in range(width)):
        return None
    if any(distances[i][j] != distances[j][i]
           for i in range(width) for j in range(i + 1, width)):
        return None
    return n, capacity, demands, distances


def _route_words(routes: list[list[int]]) -> list[int]:
    canonical = [min(route, list(reversed(route))) for route in routes]
    canonical.sort()
    words = [len(canonical)]
    for route in canonical:
        words.append(len(route))
        words.extend(route)
    return words


def _solve(n: int, capacity: int, demands: list[int],
           distances: list[list[int]]) -> list[int]:
    routes = [[customer] for customer in range(1, n + 1)]
    loads = [demands[customer] for customer in range(1, n + 1)]
    savings = [
        (distances[0][i] + distances[0][j] - distances[i][j], i, j)
        for i in range(1, n + 1) for j in range(i + 1, n + 1)
    ]
    savings.sort(key=lambda item: (-item[0], item[1], item[2]))

    for saving, i, j in savings:
        if saving <= 0:
            break
        route_i = route_j = -1
        position_i = position_j = -1
        for route_index, route in enumerate(routes):
            if i in route:
                route_i = route_index
                position_i = route.index(i)
            if j in route:
                route_j = route_index
                position_j = route.index(j)
        if route_i == route_j:
            continue
        left = routes[route_i]
        right = routes[route_j]
        if (position_i not in (0, len(left) - 1)
                or position_j not in (0, len(right) - 1)
                or loads[route_i] + loads[route_j] > capacity):
            continue
        if position_i == 0:
            left.reverse()
        if position_j == len(right) - 1:
            right.reverse()
        routes[route_i] = left + right
        loads[route_i] += loads[route_j]
        routes[route_j] = []
        loads[route_j] = 0
    return _route_words([route for route in routes if route])


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
            (type(input_length) is not int
             or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, vehicle_capacity, demands, distances = parsed
    words = _solve(n, vehicle_capacity, demands, distances)
    payload = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
