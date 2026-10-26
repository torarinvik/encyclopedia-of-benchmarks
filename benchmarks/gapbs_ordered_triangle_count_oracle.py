"""Direct, order-independent oracle for the bounded GAPBS triangle profile."""
from __future__ import annotations

from collections.abc import Sequence

MAX_NODES = 16
MAX_INPUT_LENGTH = 1 + MAX_NODES * MAX_NODES
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None) -> list[list[int]] | None:
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int for value in values):
        return None
    n = values[0]
    if not 1 <= n <= MAX_NODES or len(values) != 1 + n * n:
        return None
    matrix = [list(values[1 + row * n:1 + (row + 1) * n]) for row in range(n)]
    for row in range(n):
        if matrix[row][row] != 0:
            return None
        if any(value not in (0, 1) for value in matrix[row]):
            return None
        for column in range(row + 1, n):
            if matrix[row][column] != matrix[column][row]:
                return None
    return matrix


def expected_result(values: Sequence[int] | None) -> int:
    """Count each unordered 3-clique once using independent triple enumeration."""
    matrix = _parse(values)
    if matrix is None:
        return INVALID_RESULT
    n = len(matrix)
    total = 0
    for u in range(n):
        for v in range(u):
            if matrix[u][v] == 0:
                continue
            for w in range(v):
                if matrix[u][w] and matrix[v][w]:
                    total += 1
    return total
