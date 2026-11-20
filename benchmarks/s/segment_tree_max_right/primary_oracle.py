"""Segment-tree construction and O(log n) max_right prefix-boundary oracle."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 16
MAX_OPERATIONS = 12
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + 3 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1
MAX_VALUE = 1000
MAX_LIMIT = MAX_N * MAX_VALUE


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, int, list[int], list[tuple[int, int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, operation_count = values[:2]
    if not 0 <= n <= MAX_N or not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    if len(values) != 2 + n + 3 * operation_count:
        return None
    data = list(values[2:2 + n])
    if any(not 0 <= value <= MAX_VALUE for value in data):
        return None
    operations: list[tuple[int, int, int]] = []
    cursor = 2 + n
    for _ in range(operation_count):
        opcode, first, second = values[cursor:cursor + 3]
        cursor += 3
        if opcode == 0:
            if not 0 <= first < n or not 0 <= second <= MAX_VALUE:
                return None
        elif opcode == 1:
            if not 0 <= first <= n or not 0 <= second <= MAX_LIMIT:
                return None
        else:
            return None
        operations.append((opcode, first, second))
    return n, operation_count, data, operations


def _tree_max_right(tree: list[int], size: int, n: int,
                    left: int, limit: int) -> int:
    if left == n:
        return n
    position = left + size
    accumulated = 0
    while True:
        while position % 2 == 0:
            position //= 2
        if accumulated + tree[position] > limit:
            while position < size:
                position *= 2
                if accumulated + tree[position] <= limit:
                    accumulated += tree[position]
                    position += 1
            return min(position - size, n)
        accumulated += tree[position]
        position += 1
        if position & (position - 1) == 0:
            return n


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT
    n, _, data, operations = decoded
    size = 1
    while size < n:
        size *= 2
    tree = [0] * (2 * size)
    for i, value in enumerate(data):
        tree[size + i] = value
    for node in range(size - 1, 0, -1):
        tree[node] = tree[2 * node] + tree[2 * node + 1]

    answer_count = 0
    result = 0
    for opcode, first, second in operations:
        if opcode == 0:
            node = size + first
            tree[node] = second
            node //= 2
            while node > 0:
                tree[node] = tree[2 * node] + tree[2 * node + 1]
                node //= 2
        else:
            boundary = _tree_max_right(tree, size, n, first, second)
            result |= boundary << (5 * answer_count)
            answer_count += 1
    return result
