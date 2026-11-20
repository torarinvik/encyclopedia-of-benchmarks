"""Residue-aware two-dimensional interval-DP reference."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_K,
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_STONE,
    MIN_STONE,
)


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
    if not 1 <= n <= MAX_N or not 2 <= merge_count <= MAX_K or len(values) != n + 2:
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
    stride = merge_count - 1
    if (n - 1) % stride != 0:
        return -1

    prefix = [0] * (n + 1)
    for i, stone in enumerate(stones, start=1):
        prefix[i] = prefix[i - 1] + stone

    # This state keeps the cheapest reduction to the residue-determined
    # minimum number of piles for each interval, rather than a pile-count axis.
    dp = [[0] * n for _ in range(n)]
    for length in range(2, n + 1):
        for left in range(n - length + 1):
            right = left + length - 1
            best: int | None = None
            for cut in range(left, right, stride):
                cost = dp[left][cut] + dp[cut + 1][right]
                if best is None or cost < best:
                    best = cost
            assert best is not None
            dp[left][right] = best
            if (length - 1) % stride == 0:
                dp[left][right] += prefix[right + 1] - prefix[left]
    return dp[0][n - 1]
