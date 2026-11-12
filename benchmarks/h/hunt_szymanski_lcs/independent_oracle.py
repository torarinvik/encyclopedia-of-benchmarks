"""Independent full-table dynamic-programming oracle for LCS length."""

from __future__ import annotations

from .primary_oracle import MAX_INPUT_LENGTH, MAX_SEQUENCE_LENGTH, MAX_SYMBOL


def expected_result(values: object) -> int:
    if not isinstance(values, list) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return -1
    n, m = values[0], values[1]
    if (not isinstance(n, int) or isinstance(n, bool)
            or not isinstance(m, int) or isinstance(m, bool)
            or not 0 <= n <= MAX_SEQUENCE_LENGTH
            or not 0 <= m <= MAX_SEQUENCE_LENGTH
            or len(values) != 2 + n + m):
        return -1
    left, right = values[2:2 + n], values[2 + n:]
    if any(not isinstance(value, int) or isinstance(value, bool)
           or not 0 <= value <= MAX_SYMBOL for value in left + right):
        return -1

    table = [[0] * (m + 1) for _ in range(n + 1)]
    for i in range(1, n + 1):
        for j in range(1, m + 1):
            if left[i - 1] == right[j - 1]:
                table[i][j] = table[i - 1][j - 1] + 1
            else:
                table[i][j] = max(table[i - 1][j], table[i][j - 1])
    return table[n][m]
