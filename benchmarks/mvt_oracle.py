"""Reference model for the bounded PolyBench/C MVT kernel."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_DIMENSION = 64
MAX_INPUT_LENGTH = 1


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) != 1
            or type(values[0]) is not int or not 1 <= values[0] <= MAX_DIMENSION):
        return INVALID_RESULT

    n = values[0]
    x1 = [float(i % n) / float(n) for i in range(n)]
    x2 = [float((i + 1) % n) / float(n) for i in range(n)]
    y1 = [float((i + 3) % n) / float(n) for i in range(n)]
    y2 = [float((i + 4) % n) / float(n) for i in range(n)]
    matrix = [float((i * j) % n) / float(n) for i in range(n) for j in range(n)]

    for i in range(n):
        for j in range(n):
            x1[i] = x1[i] + matrix[i * n + j] * y1[j]
    for i in range(n):
        for j in range(n):
            x2[i] = x2[i] + matrix[j * n + i] * y2[j]

    checksum = 0.0
    for i in range(n):
        checksum += x1[i]
    for i in range(n):
        checksum += x2[i]
    return checksum
