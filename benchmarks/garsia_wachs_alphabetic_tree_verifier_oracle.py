"""Independent interval-DP optimum and ordered-tree certificate verifier."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 64
MAX_WEIGHT = 1_000_000
MAX_OUTPUT_BYTES = 8 * (MAX_N + 1)


def _parse_input(values: Sequence[int] | None, input_is_null: bool,
                 input_length: int | None) -> list[int] | None:
    if (input_is_null or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_N + 2
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != n + 1:
        return None
    weights = list(values[1:])
    if any(not 0 <= weight <= MAX_WEIGHT for weight in weights):
        return None
    return weights


def _interval_optimum(weights: list[int]) -> int:
    n = len(weights)
    if n == 1:
        return 0
    prefix = [0]
    for weight in weights:
        prefix.append(prefix[-1] + weight)
    dp = [[0] * n for _ in range(n)]
    for length in range(2, n + 1):
        for left in range(n - length + 1):
            right = left + length - 1
            interval_sum = prefix[right + 1] - prefix[left]
            dp[left][right] = interval_sum + min(
                dp[left][split] + dp[split + 1][right]
                for split in range(left, right)
            )
    return dp[0][n - 1]


def _is_ordered_full_depth_sequence(depths: list[int]) -> bool:
    if len(depths) == 1:
        return depths == [0]
    stack: list[int] = []
    for depth in depths:
        if not 1 <= depth < len(depths):
            return False
        stack.append(depth)
        while len(stack) >= 2 and stack[-1] == stack[-2]:
            level = stack.pop()
            stack.pop()
            if level <= 0:
                return False
            stack.append(level - 1)
    return stack == [0]


def verify_result(values: Sequence[int] | None, result: int, output: bytes,
                  output_capacity: int | None = None, output_is_null: bool = False,
                  input_is_null: bool = False, input_length: int | None = None) -> bool:
    weights = _parse_input(values, input_is_null, input_length)
    if weights is None:
        return result == -1 and output == b""
    required = 8 * (len(weights) + 1)
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if type(output_is_null) is not bool or type(capacity) is not int or capacity < 0:
        return result == -2 and output == b""
    if output_is_null or capacity < required:
        return result == -2 and output == b""
    if not isinstance(output, (bytes, bytearray)) or result != required or len(output) != required:
        return False
    try:
        words = struct.unpack("<" + "q" * (len(weights) + 1), output)
    except struct.error:
        return False
    cost, *depths = words
    if not _is_ordered_full_depth_sequence(depths):
        return False
    measured = sum(weight * depth for weight, depth in zip(weights, depths))
    return cost == measured == _interval_optimum(weights)
