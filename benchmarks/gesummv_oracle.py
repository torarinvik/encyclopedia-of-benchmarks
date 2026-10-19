"""Reference model for the bounded PolyBench/C gesummv kernel."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_DIMENSION = 64
MAX_INPUT_LENGTH = 1


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) != 1
            or type(values[0]) is not int or not 1 <= values[0] <= MAX_DIMENSION):
        return INVALID_RESULT

    n = values[0]
    x = [(i % n) / n for i in range(n)]
    result = 0.0
    for i in range(n):
        temporary = 0.0
        y = 0.0
        for j in range(n):
            a = ((i * j + 1) % n) / n
            b = ((i * j + 2) % n) / n
            temporary = a * x[j] + temporary
            y = b * x[j] + y
        y = 1.5 * temporary + 1.2 * y
        result += y
    return result
