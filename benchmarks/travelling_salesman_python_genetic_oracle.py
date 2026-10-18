"""Oracle for the bounded two-city domain of the pinned Python genetic TSP."""

from __future__ import annotations

import math
from collections.abc import Sequence


def expected_output(values: Sequence[object] | None, capacity: int | None = None,
                    output_is_null: bool = False) -> tuple[int, list[float]]:
    if not isinstance(values, (list, tuple)) or len(values) != 8:
        return -1, []
    if any(type(value) not in (int, float) for value in values):
        return -1, []
    population, iterations = values[:2]
    crossover, mutation = map(float, values[2:4])
    coords = values[4:]
    if any(not math.isfinite(float(value)) for value in values):
        return -1, []
    if population != int(population) or not 2 <= population <= 8 or int(population) % 2:
        return -1, []
    if iterations != int(iterations) or not 0 <= iterations <= 12:
        return -1, []
    if not 0.0 <= crossover <= 1.0 or not 0.0 <= mutation <= 1.0:
        return -1, []
    if any(value != int(value) or not -16 <= value <= 16 for value in coords):
        return -1, []
    x0, y0, x1, y1 = map(float, coords)
    if x0 == x1 and y0 == y1:
        return -1, []
    distance = ((x0 - x1) ** 2 + (y0 - y1) ** 2) ** 0.5
    result = [3.0, 0.0, 1.0, 0.0, 2.0 * distance]
    if type(output_is_null) is not bool or (capacity is not None and (type(capacity) is not int or capacity < 0)):
        return -1, []
    if output_is_null or (capacity is not None and capacity < len(result)):
        return -2, []
    return len(result), result


def expected_result(values: Sequence[object] | None) -> tuple[int, list[float]]:
    return expected_output(values)
