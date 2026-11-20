"""Lazy sum-tree oracle with range additions and tree-guided max_right."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 16
MAX_OPERATIONS = 12
MAX_VALID_INPUT_LENGTH = 66
MAX_PARSEABLE_INPUT_LENGTH = 67
MAX_VALUE = 31
MAX_LIMIT = 8192
INVALID_RESULT = -1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, list[int], list[tuple[int, int, int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, operation_count = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    if len(values) != 2 + n + 4 * operation_count or len(values) > MAX_VALID_INPUT_LENGTH:
        return None
    data = list(values[2:2 + n])
    if any(not 0 <= value <= MAX_VALUE for value in data):
        return None

    operations: list[tuple[int, int, int, int]] = []
    cursor = 2 + n
    for _ in range(operation_count):
        opcode, left, right, extra = values[cursor:cursor + 4]
        cursor += 4
        if opcode == 0:
            if not 0 <= left <= n or not left <= right <= n or not 0 <= extra <= MAX_VALUE:
                return None
        elif opcode == 1:
            if not 0 <= left <= n or not 0 <= right <= MAX_LIMIT or extra != 0:
                return None
        else:
            return None
        operations.append((opcode, left, right, extra))
    return n, data, operations


def _apply(tree: list[int], pending: list[int], node: int,
           segment_length: int, delta: int) -> None:
    tree[node] += delta * segment_length
    pending[node] += delta


def _push(tree: list[int], pending: list[int], node: int,
          segment_length: int) -> None:
    if segment_length > 1 and pending[node] != 0:
        half = segment_length // 2
        delta = pending[node]
        _apply(tree, pending, 2 * node, half, delta)
        _apply(tree, pending, 2 * node + 1, half, delta)
        pending[node] = 0


def _range_add(tree: list[int], pending: list[int], node: int,
               low: int, high: int, query_low: int, query_high: int,
               delta: int) -> None:
    if query_low >= query_high:
        return
    if query_high <= low or high <= query_low:
        return
    if query_low <= low and high <= query_high:
        _apply(tree, pending, node, high - low, delta)
        return
    _push(tree, pending, node, high - low)
    middle = (low + high) // 2
    if query_low < middle:
        _range_add(tree, pending, 2 * node, low, middle, query_low, query_high, delta)
    if query_high > middle:
        _range_add(tree, pending, 2 * node + 1, middle, high, query_low, query_high, delta)
    tree[node] = tree[2 * node] + tree[2 * node + 1]


def _max_right(tree: list[int], pending: list[int], node: int,
               low: int, high: int, n: int, left: int,
               limit: int, accumulated: list[int]) -> int:
    if high <= left:
        return high
    if low >= n:
        return n
    if left <= low and high <= n and accumulated[0] + tree[node] <= limit:
        accumulated[0] += tree[node]
        return high
    if high - low == 1:
        return low
    _push(tree, pending, node, high - low)
    middle = (low + high) // 2
    first = _max_right(tree, pending, 2 * node, low, middle,
                       n, left, limit, accumulated)
    if first < middle and first >= left:
        return first
    return _max_right(tree, pending, 2 * node + 1, middle, high,
                      n, left, limit, accumulated)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT
    n, data, operations = decoded
    size = 1
    while size < n:
        size *= 2
    tree = [0] * (2 * size)
    pending = [0] * (2 * size)
    for i, value in enumerate(data):
        tree[size + i] = value
    for node in range(size - 1, 0, -1):
        tree[node] = tree[2 * node] + tree[2 * node + 1]

    result = 0
    query_index = 0
    for opcode, left, right, extra in operations:
        if opcode == 0:
            _range_add(tree, pending, 1, 0, size, left, right, extra)
        else:
            accumulated = [0]
            boundary = _max_right(tree, pending, 1, 0, size,
                                  n, left, right, accumulated)
            result |= boundary << (5 * query_index)
            query_index += 1
    return result
