"""Reference model for the bounded PolyBench/C covariance kernel."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_DIMENSION = 64
MAX_INPUT_LENGTH = 2


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    n, m = values
    if not (2 <= n <= MAX_DIMENSION and 1 <= m <= MAX_DIMENSION):
        return INVALID_RESULT

    float_n = float(n)
    data = [0.0] * (n * m)
    covariance = [0.0] * (m * m)
    mean = [0.0] * m
    for i in range(n):
        for j in range(m):
            data[i * m + j] = (float(i) * j) / m

    for j in range(m):
        mean[j] = 0.0
        for i in range(n):
            mean[j] += data[i * m + j]
        mean[j] /= float_n

    for i in range(n):
        for j in range(m):
            data[i * m + j] -= mean[j]

    for i in range(m):
        for j in range(i, m):
            covariance[i * m + j] = 0.0
            for k in range(n):
                covariance[i * m + j] += data[k * m + i] * data[k * m + j]
            covariance[i * m + j] /= float_n - 1.0
            covariance[j * m + i] = covariance[i * m + j]

    checksum = 0.0
    for i in range(m):
        for j in range(m):
            checksum += covariance[i * m + j]
    return checksum
