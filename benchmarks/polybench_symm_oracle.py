"""Reference model for the bounded PolyBench/C SYMM kernel."""

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

    alpha = 1.5
    beta = 1.2
    c = [0.0] * (m * n)
    a = [0.0] * (m * m)
    b = [0.0] * (m * n)
    for i in range(m):
        for j in range(n):
            c[i * n + j] = float((i + j) % 100) / float(m)
            b[i * n + j] = float((n + i - j) % 100) / float(m)
    for i in range(m):
        for j in range(m):
            a[i * m + j] = (float((i + j) % 100) / float(m)) if j <= i else -999.0

    for i in range(m):
        for j in range(n):
            temp2 = 0.0
            for k in range(i):
                c[k * n + j] = c[k * n + j] + alpha * b[i * n + j] * a[i * m + k]
                temp2 = temp2 + b[k * n + j] * a[i * m + k]
            c[i * n + j] = (
                beta * c[i * n + j]
                + alpha * b[i * n + j] * a[i * m + i]
                + alpha * temp2
            )

    result = 0.0
    for i in range(m):
        for j in range(n):
            result += c[i * n + j]
    return result
