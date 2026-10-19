"""Reference model for the bounded PolyBench/C ATAX kernel."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_DIMENSION = 64
MAX_INPUT_LENGTH = 2


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    m, n = values
    if not (1 <= m <= MAX_DIMENSION and 1 <= n <= MAX_DIMENSION):
        return INVALID_RESULT

    x = [1.0 + float(i) / float(n) for i in range(n)]
    matrix = [float((i + j) % n) / float(5 * m) for i in range(m) for j in range(n)]
    y = [0.0] * n
    temporary = [0.0] * m
    for i in range(n):
        y[i] = 0.0
    for i in range(m):
        temporary[i] = 0.0
        for j in range(n):
            temporary[i] = temporary[i] + matrix[i * n + j] * x[j]
        for j in range(n):
            y[j] = y[j] + matrix[i * n + j] * temporary[i]

    checksum = 0.0
    for j in range(n):
        checksum += y[j]
    return checksum
