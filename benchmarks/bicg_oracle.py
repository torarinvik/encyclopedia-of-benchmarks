"""Reference model for the bounded PolyBench/C BiCG kernel."""

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

    p = [float(i % m) / float(m) for i in range(m)]
    r = [float(i % n) / float(n) for i in range(n)]
    matrix = [float((i * (j + 1)) % n) / float(n) for i in range(n) for j in range(m)]
    s = [0.0] * m
    q = [0.0] * n
    for i in range(n):
        q[i] = 0.0
        for j in range(m):
            s[j] = s[j] + r[i] * matrix[i * m + j]
            q[i] = q[i] + matrix[i * m + j] * p[j]

    checksum = 0.0
    for j in range(m):
        checksum += s[j]
    for i in range(n):
        checksum += q[i]
    return checksum
