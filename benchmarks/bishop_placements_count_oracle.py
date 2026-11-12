"""Primary color-separated diagonal recurrence for bishop placements."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_K = 2 * MAX_N


def _read(values: Sequence[int] | None) -> tuple[int, int] | None:
    if not isinstance(values, (list, tuple)) or len(values) != 2:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, k = values
    if not 1 <= n <= MAX_N or not 0 <= k <= MAX_K:
        return None
    return n, k


def _diagonal_size(index: int) -> int:
    if index & 1:
        return (index // 4) * 2 + 1
    return ((index - 1) // 4) * 2 + 2


def _same_color_counts(n: int, k: int, final_diagonal: int) -> list[int]:
    table = [[0] * (k + 1) for _ in range(2 * n)]
    table[0][0] = 1
    table[1][0] = 1
    if k >= 1:
        table[1][1] = 1
    for diagonal in range(2, final_diagonal + 1):
        table[diagonal][0] = 1
        squares = _diagonal_size(diagonal)
        for placed in range(1, k + 1):
            without_current = table[diagonal - 2][placed]
            with_current = table[diagonal - 2][placed - 1] * (squares - placed + 1)
            table[diagonal][placed] = without_current + with_current
    return table[final_diagonal]


def expected_result(values: Sequence[int] | None) -> int:
    parsed = _read(values)
    if parsed is None:
        return -1
    n, k = parsed
    maximum = 1 if n == 1 else 2 * n - 2
    if k > maximum:
        return 0
    black = _same_color_counts(n, k, 2 * n - 1)
    white = _same_color_counts(n, k, 2 * n - 2)
    return sum(black[left] * white[k - left] for left in range(k + 1))
