"""Prefix partition DP for minimum run-length size after deletions."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 12
MAX_ALPHABET_SYMBOL = 25
MAX_VALID_INPUT_LENGTH = 14
MAX_PARSEABLE_INPUT_LENGTH = 15
WORKSPACE_BYTES = 2048
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
_INF = 1 << 60


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[list[int], int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    n, deletions = values[0], values[1]
    if not 0 <= n <= MAX_N or not 0 <= deletions <= n:
        return None
    if len(values) != n + 2:
        return None
    symbols = list(values[2:])
    if any(not 0 <= symbol <= MAX_ALPHABET_SYMBOL for symbol in symbols):
        return None
    return symbols, deletions


def _run_cost(length: int) -> int:
    if length == 1:
        return 1
    digits = 1
    while length >= 10:
        length //= 10
        digits += 1
    return 1 + digits


def _minimum_length(symbols: list[int], deletion_budget: int) -> int:
    n = len(symbols)
    dp = [[_INF] * (deletion_budget + 1) for _ in range(n + 1)]
    dp[0][0] = 0

    for start in range(n):
        for used in range(deletion_budget + 1):
            prefix_cost = dp[start][used]
            if prefix_cost == _INF:
                continue

            if used < deletion_budget:
                dp[start + 1][used + 1] = min(
                    dp[start + 1][used + 1], prefix_cost
                )

            symbol = symbols[start]
            same_count = 0
            for end in range(start, n):
                if symbols[end] == symbol:
                    same_count += 1
                span = end - start + 1
                for kept_count in range(1, same_count + 1):
                    extra_deletions = span - kept_count
                    total_deletions = used + extra_deletions
                    if total_deletions > deletion_budget:
                        continue
                    candidate = prefix_cost + _run_cost(kept_count)
                    if candidate < dp[end + 1][total_deletions]:
                        dp[end + 1][total_deletions] = candidate

    return min(dp[n])


def expected_result(values: Sequence[int] | None, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1
    symbols, deletions = parsed
    return _minimum_length(symbols, deletions)
