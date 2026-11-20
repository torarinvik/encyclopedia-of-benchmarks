"""Online rectangle counts using a Fenwick tree over x-blocks of y-Fenwicks."""

from __future__ import annotations

from collections.abc import Sequence
from math import isqrt

MAX_N = 24
MAX_Q = 32
WORDS_PER_OPERATION = 5
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + WORDS_PER_OPERATION * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = (MAX_Q * (MAX_Q + 1) // 2) * MAX_N
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[int], list[tuple[int, ...]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None

    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q:
        return None
    if len(values) != 2 + n + WORDS_PER_OPERATION * q:
        return None
    y_values = list(values[2:2 + n])
    if any(not 0 <= y < n for y in y_values):
        return None

    operations: list[tuple[int, ...]] = []
    cursor = 2 + n
    for _ in range(q):
        op = tuple(values[cursor:cursor + WORDS_PER_OPERATION])
        cursor += WORDS_PER_OPERATION
        kind = op[0]
        if kind == 0:
            _, x, new_y, pad_a, pad_b = op
            if not (0 <= x < n and 0 <= new_y < n and pad_a == 0 and pad_b == 0):
                return None
        elif kind == 1:
            _, x_left, x_right, y_low, y_high = op
            if not (0 <= x_left <= x_right <= n
                    and 0 <= y_low <= y_high <= n):
                return None
        else:
            return None
        operations.append(op)
    return n, y_values, operations


def _inner_add(tree: list[int], n: int, y: int, delta: int) -> None:
    index = y + 1
    while index <= n:
        tree[index] += delta
        index += index & -index


def _inner_prefix(tree: list[int], y_limit: int) -> int:
    total = 0
    index = y_limit
    while index > 0:
        total += tree[index]
        index -= index & -index
    return total


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, y_values, operations = parsed
    block_size = isqrt(n - 1) + 1
    block_count = (n + block_size - 1) // block_size
    outer = [[0] * (n + 1) for _ in range(block_count + 1)]

    def apply_value(block_tree: list[int], y: int, delta: int) -> None:
        _inner_add(block_tree, n, y, delta)

    def update(x: int, new_y: int) -> None:
        old_y = y_values[x]
        node = x // block_size + 1
        while node <= block_count:
            apply_value(outer[node], old_y, -1)
            apply_value(outer[node], new_y, 1)
            node += node & -node
        y_values[x] = new_y

    def prefix_count(x_limit: int, y_limit: int) -> int:
        full_blocks, _ = divmod(x_limit, block_size)
        total = 0
        node = full_blocks
        while node > 0:
            total += _inner_prefix(outer[node], y_limit)
            node -= node & -node
        for x in range(full_blocks * block_size, x_limit):
            if y_values[x] < y_limit:
                total += 1
        return total

    for x, y in enumerate(y_values):
        node = x // block_size + 1
        while node <= block_count:
            apply_value(outer[node], y, 1)
            node += node & -node

    checksum = 0
    query_ordinal = 0
    for op in operations:
        if op[0] == 0:
            update(op[1], op[2])
        else:
            _, x_left, x_right, y_low, y_high = op
            count = (prefix_count(x_right, y_high) - prefix_count(x_left, y_high)
                     - prefix_count(x_right, y_low) + prefix_count(x_left, y_low))
            query_ordinal += 1
            checksum += query_ordinal * count
    return checksum
