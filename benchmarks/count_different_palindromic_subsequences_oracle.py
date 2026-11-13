"""Quadratic interval DP for distinct nonempty palindromic subsequences."""

from __future__ import annotations

from collections.abc import Sequence

MODULUS = 1_000_000_007
MAX_LENGTH = 20
ALPHABET_SIZE = 4
MAX_VALID_INPUT_LENGTH = MAX_LENGTH + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1


def expected_result(values: Sequence[int] | None) -> int:
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return -1
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1
    n = values[0]
    if type(n) is not int or not 0 <= n <= MAX_LENGTH or len(values) != n + 1:
        return -1
    symbols = values[1:]
    if any(not 0 <= symbol < ALPHABET_SIZE for symbol in symbols):
        return -1
    if n == 0:
        return 0

    next_equal = [n] * n
    previous_equal = [-1] * n
    next_at = [n] * ALPHABET_SIZE
    previous_at = [-1] * ALPHABET_SIZE
    for i in range(n - 1, -1, -1):
        symbol = symbols[i]
        next_equal[i] = next_at[symbol]
        next_at[symbol] = i
    for i, symbol in enumerate(symbols):
        previous_equal[i] = previous_at[symbol]
        previous_at[symbol] = i

    dp = [[0] * n for _ in range(n)]
    for i in range(n):
        dp[i][i] = 1
    for width in range(2, n + 1):
        for left in range(n - width + 1):
            right = left + width - 1
            if symbols[left] != symbols[right]:
                inner = dp[left + 1][right - 1] if width > 2 else 0
                dp[left][right] = (dp[left + 1][right] + dp[left][right - 1] - inner) % MODULUS
                continue
            inner = dp[left + 1][right - 1] if width > 2 else 0
            first = next_equal[left]
            last = previous_equal[right]
            if first >= right or last <= left or first > last:
                value = 2 * inner + 2
            elif first == last:
                value = 2 * inner + 1
            else:
                inside_duplicates = dp[first + 1][last - 1] if first + 1 <= last - 1 else 0
                value = 2 * inner - inside_duplicates
            dp[left][right] = value % MODULUS
    return dp[0][n - 1]
