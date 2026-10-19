"""Bounded source-order oracle for the PolyBench Nussinov benchmark."""

from __future__ import annotations

INVALID_RESULT = -1
MAX_N = 128
MAX_INPUT_LENGTH = 2


def expected_result(values: list[int]) -> int:
    """Return the sum of the source table's upper triangle, or -1 if invalid."""
    if (not isinstance(values, list) or len(values) != 1
            or type(values[0]) is not int or not 1 <= values[0] <= MAX_N):
        return INVALID_RESULT

    n = values[0]
    bases = [(i + 1) % 4 for i in range(n)]
    table = [[0] * n for _ in range(n)]

    for i in range(n - 1, -1, -1):
        for j in range(i + 1, n):
            score = table[i][j - 1]
            if i + 1 < n:
                score = max(score, table[i + 1][j])
                if j - 1 >= 0:
                    inside = table[i + 1][j - 1]
                    if i < j - 1 and bases[i] + bases[j] == 3:
                        inside += 1
                    score = max(score, inside)
            for k in range(i + 1, j):
                score = max(score, table[i][k] + table[k + 1][j])
            table[i][j] = score

    return sum(table[i][j] for i in range(n) for j in range(i, n))
