"""Reference model for the bounded lac-dcc BenchmarkGame spectral norm."""

from __future__ import annotations

import math

INVALID_RESULT = -1e300
MAX_DIMENSION = 64
MAX_INPUT_LENGTH = 1


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) != 1
            or type(values[0]) is not int or not 1 <= values[0] <= MAX_DIMENSION):
        return INVALID_RESULT

    n = values[0]

    def matrix_entry(i: int, j: int) -> float:
        return 1.0 / (((i + j) * (i + j + 1) // 2) + i + 1)

    def multiply(vector: list[float], transpose: bool) -> list[float]:
        result = [0.0] * n
        for i in range(n):
            total = 0.0
            for j in range(n):
                total += (matrix_entry(j, i) if transpose else matrix_entry(i, j)) * vector[j]
            result[i] = total
        return result

    def ata(vector: list[float]) -> list[float]:
        return multiply(multiply(vector, False), True)

    u = [1.0] * n
    v = [0.0] * n
    for _ in range(10):
        v = ata(u)
        u = ata(v)

    v_b_v = 0.0
    v_v = 0.0
    for i in range(n):
        v_b_v += u[i] * v[i]
        v_v += v[i] * v[i]
    return math.sqrt(v_b_v / v_v)
