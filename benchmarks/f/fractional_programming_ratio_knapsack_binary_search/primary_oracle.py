"""Ratio bisection with denominator-capped 0/1 knapsack feasibility."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 12
MAX_WEIGHT = 32
MAX_VALID_INPUT_LENGTH = 26
MAX_PARSEABLE_INPUT_LENGTH = 27
SCALE = 1_000_000
MAX_SCALED_RATIO = 1_000_000_000
MAX_RESULT = MAX_SCALED_RATIO
MAX_WORKSPACE_BYTES = 2_048
INVALID_RESULT = -1
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1
NEGATIVE_INFINITY = -(1 << 61)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[list[int], list[int], int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) < 2:
        return None
    n, required = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= required <= MAX_WEIGHT:
        return None
    if len(values) != 2 + 2 * n:
        return None
    numerators: list[int] = []
    denominators: list[int] = []
    for item in range(n):
        numerator, denominator = values[2 + 2 * item:4 + 2 * item]
        if not 0 <= numerator <= 1000 or not 1 <= denominator <= 8:
            return None
        numerators.append(numerator)
        denominators.append(denominator)
    if sum(denominators) < required:
        return None
    return numerators, denominators, required


def _feasible(numerators: list[int], denominators: list[int],
              required: int, threshold: int) -> bool:
    dp = [NEGATIVE_INFINITY] * (required + 1)
    dp[0] = 0
    for numerator, denominator in zip(numerators, denominators, strict=True):
        updated = dp.copy()
        score = SCALE * numerator - threshold * denominator
        for weight, prior in enumerate(dp):
            if prior == NEGATIVE_INFINITY:
                continue
            target = min(required, weight + denominator)
            updated[target] = max(updated[target], prior + score)
        dp = updated
    return dp[required] >= 0


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    numerators, denominators, required = parsed
    low, high = 0, MAX_SCALED_RATIO + 1
    while high - low > 1:
        middle = low + (high - low) // 2
        if _feasible(numerators, denominators, required, middle):
            low = middle
        else:
            high = middle
    return low
