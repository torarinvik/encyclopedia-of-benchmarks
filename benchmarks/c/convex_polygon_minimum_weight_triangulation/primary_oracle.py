"""Interval-DP reference for additive convex-polygon triangulation weights."""

from __future__ import annotations

from collections.abc import Sequence

MIN_VERTICES = 3
MAX_VERTICES = 10
MAX_DIAGONAL_WEIGHT = 1000
MAX_VALID_INPUT_LENGTH = 36
MAX_PARSEABLE_INPUT_LENGTH = 37
MAX_RESULT = 7000
WORKSPACE_BYTES = 2048
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, dict[tuple[int, int], int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    n = values[0]
    if not MIN_VERTICES <= n <= MAX_VERTICES:
        return None
    diagonals = tuple(
        (i, j)
        for i in range(n)
        for j in range(i + 2, n)
        if not (i == 0 and j == n - 1)
    )
    if len(values) != 1 + len(diagonals):
        return None
    weights: dict[tuple[int, int], int] = {}
    for edge, weight in zip(diagonals, values[1:]):
        if not 0 <= weight <= MAX_DIAGONAL_WEIGHT:
            return None
        weights[edge] = weight
    return n, weights


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return the minimum total internal-diagonal weight, or -1 if malformed."""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, weights = parsed

    def edge_cost(i: int, j: int) -> int:
        if j - i == 1 or (i == 0 and j == n - 1):
            return 0
        return weights[(i, j)]

    # dp[i][j] excludes its boundary chord (i,j); a parent charges that chord
    # once when it becomes one of the two child boundaries.
    dp = [[0] * n for _ in range(n)]
    for span in range(2, n):
        for left in range(n - span):
            right = left + span
            best = MAX_RESULT + 1
            for split in range(left + 1, right):
                candidate = (dp[left][split] + dp[split][right]
                             + edge_cost(left, split) + edge_cost(split, right))
                if candidate < best:
                    best = candidate
            dp[left][right] = best
    return dp[0][n - 1]


expected_output = expected_result
