"""Pile-count interval-DP reference for bounded k-ary stone merging."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 30
MAX_K = 30
MIN_STONE = 1
MAX_STONE = 100
MAX_VALID_INPUT_LENGTH = 32
MAX_PARSEABLE_INPUT_LENGTH = 33
WORKSPACE_BYTES = 262_144
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INF = 1 << 60


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[int, int, list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    n, merge_count = values[0], values[1]
    if not 1 <= n <= MAX_N or not 2 <= merge_count <= MAX_K:
        return None
    if len(values) != n + 2:
        return None
    stones = list(values[2:])
    if len(stones) != n or any(not MIN_STONE <= stone <= MAX_STONE for stone in stones):
        return None
    return n, merge_count, stones


def expected_result(values: Sequence[int] | None, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1
    n, merge_count, stones = parsed
    if (n - 1) % (merge_count - 1) != 0:
        return -1

    prefix = [0] * (n + 1)
    for i, stone in enumerate(stones, start=1):
        prefix[i] = prefix[i - 1] + stone

    dp = [[[INF] * (merge_count + 1) for _ in range(n)] for _ in range(n)]
    for i in range(n):
        dp[i][i][1] = 0

    for length in range(2, n + 1):
        for left in range(n - length + 1):
            right = left + length - 1
            for piles in range(2, min(merge_count, length) + 1):
                best = INF
                for cut in range(left, right):
                    first = dp[left][cut][1]
                    rest = dp[cut + 1][right][piles - 1]
                    if first < INF and rest < INF and first + rest < best:
                        best = first + rest
                dp[left][right][piles] = best
            if length >= merge_count and dp[left][right][merge_count] < INF:
                interval_sum = prefix[right + 1] - prefix[left]
                dp[left][right][1] = dp[left][right][merge_count] + interval_sum

    answer = dp[0][n - 1][1]
    return -1 if answer >= INF else answer
