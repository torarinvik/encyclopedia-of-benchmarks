"""Independent full-table Levenshtein verifier over implicit RLE symbols."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_LENGTH = 18


def _read(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    left_count = values[0]
    if left_count < 1 or left_count > 4:
        return None
    right_index = 1 + 2 * left_count
    if right_index >= len(values):
        return None
    right_count = values[right_index]
    if right_count < 1 or right_count > 4 or len(values) != right_index + 1 + 2 * right_count:
        return None

    def runs_at(offset: int, count: int):
        result = []
        total = 0
        for index in range(count):
            symbol = values[offset + 2 * index]
            length = values[offset + 2 * index + 1]
            if symbol < 0 or symbol > 3 or length < 1 or length > 8:
                return None
            total += length
            if total > 16:
                return None
            result.append((symbol, length))
        return result

    left = runs_at(1, left_count)
    right = runs_at(right_index + 1, right_count)
    if left is None or right is None:
        return None
    return left, right


def _symbol_at(runs: list[tuple[int, int]], position: int) -> int:
    for symbol, length in runs:
        if position < length:
            return symbol
        position -= length
    raise IndexError("expanded offset is outside the encoded string")


def expected_result(values: Sequence[int] | None) -> int:
    parsed = _read(values)
    if parsed is None:
        return -1
    left, right = parsed
    n = sum(length for _, length in left)
    m = sum(length for _, length in right)
    dp = [[0] * (m + 1) for _ in range(n + 1)]
    for i in range(n + 1):
        dp[i][0] = i
    for j in range(m + 1):
        dp[0][j] = j
    for i in range(1, n + 1):
        a = _symbol_at(left, i - 1)
        for j in range(1, m + 1):
            substitution = 0 if a == _symbol_at(right, j - 1) else 1
            dp[i][j] = min(dp[i - 1][j] + 1, dp[i][j - 1] + 1,
                           dp[i - 1][j - 1] + substitution)
    return dp[n][m]
