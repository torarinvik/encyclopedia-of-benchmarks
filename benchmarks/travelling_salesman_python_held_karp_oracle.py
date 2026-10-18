"""Oracle for the pinned Python Held-Karp dynamic-programming TSP method."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_CITIES = 2
MAX_CITIES = 8
COORDINATE_BOUND = 16
MAX_INPUT_LENGTH = 1 + 2 * MAX_CITIES
MAX_OUTPUT_ELEMENTS = MAX_CITIES + 3


def _decode(values: Sequence[object] | None) -> list[tuple[float, float]] | None:
    if not isinstance(values, (list, tuple)) or not MIN_CITIES + 1 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) not in (int, float) for value in values):
        return None
    count = values[0]
    if type(count) not in (int, float) or not math.isfinite(float(count)) or count != int(count):
        return None
    count = int(count)
    if not MIN_CITIES <= count <= MAX_CITIES or len(values) != 1 + 2 * count:
        return None
    coordinates: list[tuple[float, float]] = []
    for i in range(count):
        x, y = values[1 + 2 * i: 3 + 2 * i]
        if any(not math.isfinite(float(v)) or not -COORDINATE_BOUND <= v <= COORDINATE_BOUND or v != int(v) for v in (x, y)):
            return None
        coordinates.append((float(x), float(y)))
    return coordinates


def _distance(a: tuple[float, float], b: tuple[float, float]) -> float:
    return math.sqrt((b[0] - a[0]) ** 2 + (b[1] - a[1]) ** 2)


def expected_output(values: Sequence[object] | None, capacity: int | None = None,
                    output_is_null: bool = False) -> tuple[int, list[float]]:
    points = _decode(values)
    if points is None:
        return -1, []
    if type(output_is_null) is not bool or (capacity is not None and (type(capacity) is not int or capacity < 0)):
        return -1, []
    n = len(points)
    distances = [[_distance(points[i], points[j]) for j in range(n)] for i in range(n)]
    dp = [[math.inf] * n for _ in range(1 << n)]
    dp[1][0] = 0.0
    for mask in range(1 << n):
        for u in range(n):
            if mask & (1 << u):
                for v in range(n):
                    if mask & (1 << v) == 0:
                        next_mask = mask | (1 << v)
                        candidate = dp[mask][u] + distances[u][v]
                        if candidate < dp[next_mask][v]:
                            dp[next_mask][v] = candidate
    final_mask = (1 << n) - 1
    minimum = math.inf
    end_node = -1
    for u in range(1, n):
        candidate = dp[final_mask][u] + distances[u][0]
        if minimum > candidate:
            minimum = candidate
            end_node = u
    path: list[int] = []
    mask = final_mask
    while end_node != 0:
        path.append(end_node)
        for u in range(n):
            if mask & (1 << u) and dp[mask][end_node] == dp[mask ^ (1 << end_node)][u] + distances[u][end_node]:
                mask ^= 1 << end_node
                end_node = u
                break
    path.append(0)
    path.reverse()
    path.append(0)
    result = [float(len(path)), *(float(node) for node in path), minimum]
    if output_is_null or (capacity is not None and capacity < len(result)):
        return -2, []
    return len(result), result


def expected_result(values: Sequence[object] | None) -> tuple[int, list[float]]:
    return expected_output(values)
