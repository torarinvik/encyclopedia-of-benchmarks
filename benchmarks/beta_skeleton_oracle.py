"""Independent exact integer oracle for the beta=2 lune graph."""
from __future__ import annotations

from collections.abc import Sequence

MAX_N = 32
COORD_BOUND = 1000
MAX_PARSEABLE_INPUT_LENGTH = 1 + 2 * MAX_N
MAX_OUTPUT_BYTES = 2 * (MAX_N * (MAX_N - 1) // 2)
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))):
        return -1, b""
    if any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 2 * n:
        return -1, b""
    points = [(values[1 + 2 * i], values[2 + 2 * i]) for i in range(n)]
    if any(not (-COORD_BOUND <= x <= COORD_BOUND and -COORD_BOUND <= y <= COORD_BOUND)
           for x, y in points):
        return -1, b""
    if len(set(points)) != n:
        return -1, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""

    edges: list[tuple[int, int]] = []
    for i in range(n):
        xi, yi = points[i]
        for j in range(i + 1, n):
            xj, yj = points[j]
            d2 = (xi - xj) ** 2 + (yi - yj) ** 2
            blocked = False
            for k, (xk, yk) in enumerate(points):
                if k == i or k == j:
                    continue
                di2 = (xk - xi) ** 2 + (yk - yi) ** 2
                dj2 = (xk - xj) ** 2 + (yk - yj) ** 2
                if di2 < d2 and dj2 < d2:
                    blocked = True
                    break
            if not blocked:
                edges.append((i, j))

    needed = 2 * len(edges)
    if output_is_null or (output_capacity is not None and output_capacity < needed):
        return -2, b""
    return needed, bytes(component for edge in edges for component in edge)
