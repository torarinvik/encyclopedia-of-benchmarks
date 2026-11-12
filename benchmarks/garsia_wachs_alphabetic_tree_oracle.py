"""Garsia-Wachs phase-and-reconstruction oracle for bounded ordered weights."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 64
MAX_WEIGHT = 1_000_000
MAX_INPUT_VALUES = MAX_N + 1
MAX_PARSEABLE_INPUT_VALUES = MAX_INPUT_VALUES + 1
MAX_OUTPUT_BYTES = 8 * (MAX_N + 1)
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2
INFINITY = 1 << 62


def _reconstruct(depths: list[int]) -> bool:
    """Check/build an ordered full tree from its left-to-right leaf depths."""
    stack: list[tuple[int, int]] = []
    next_internal = len(depths)
    for leaf, depth in enumerate(depths):
        stack.append((leaf, depth))
        while len(stack) >= 2 and stack[-1][1] == stack[-2][1]:
            right, level = stack.pop()
            left, _ = stack.pop()
            if level <= 0:
                return False
            stack.append((next_internal, level - 1))
            next_internal += 1
    return len(stack) == 1 and stack[0][1] == 0


def _solve(weights: list[int]) -> tuple[int, list[int]] | None:
    n = len(weights)
    if n == 1:
        return 0, [0]
    node_count = 2 * n - 1
    node_weight = [0] * node_count
    left = [-1] * node_count
    right = [-1] * node_count
    node_weight[:n] = weights
    active = list(range(n))
    next_node = n

    # Stage 1: combine the first eligible adjacent pair and move its parent
    # left past smaller weights, stopping immediately after the nearest >= one.
    while len(active) > 1:
        pair = 0
        while pair <= len(active) - 2:
            following = node_weight[active[pair + 2]] if pair + 2 < len(active) else INFINITY
            if node_weight[active[pair]] <= following:
                break
            pair += 1
        first, second = active[pair], active[pair + 1]
        combined = node_weight[first] + node_weight[second]
        node_weight[next_node] = combined
        left[next_node] = first
        right[next_node] = second
        insertion = pair - 1
        while insertion >= 0 and node_weight[active[insertion]] < combined:
            insertion -= 1
        insertion += 1
        del active[pair:pair + 2]
        active.insert(insertion, next_node)
        next_node += 1

    # Stage 2: record the temporary tree's leaf depths.
    depths = [0] * n
    stack = [(active[0], 0)]
    while stack:
        node, depth = stack.pop()
        if node < n:
            depths[node] = depth
        else:
            stack.append((right[node], depth + 1))
            stack.append((left[node], depth + 1))

    # Stage 3: reconstruct the full ordered tree from those depths. The output
    # carries this canonical shape as the ordered depth sequence.
    if not _reconstruct(depths):
        return None
    cost = sum(weight * depth for weight, depth in zip(weights, depths))
    return cost, depths


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> list[int] | None:
    if (input_is_null or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_VALUES
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_VALUES))
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


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return ABI status and ``[cost, ordered_leaf_depths...]`` as LE i64s."""
    weights = _parse(values, input_is_null, input_length)
    if weights is None:
        return INVALID_RESULT, b""
    solved = _solve(weights)
    if solved is None:
        return INVALID_RESULT, b""
    cost, depths = solved
    required = 8 * (len(depths) + 1)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return OUTPUT_ERROR_RESULT, b""
    if output_is_null or effective_capacity < required:
        return OUTPUT_ERROR_RESULT, b""
    payload = struct.pack("<" + "q" * (len(depths) + 1), cost, *depths)
    return len(payload), payload


def validate_output(values: Sequence[int] | None, output: bytes) -> bool:
    result, expected = expected_output(values, capacity=MAX_OUTPUT_BYTES)
    return result == len(expected) and output == expected
