"""Fenwick tree of mutable weighted value trees for dynamic range selection."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 12
MAX_Q = 16
MIN_VALUE = -30
MAX_VALUE = 30
VALUE_COUNT = MAX_VALUE - MIN_VALUE + 1
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + 4 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
NODE_CAPACITY = 1280
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[list[int], list[tuple[int, int, int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q or len(values) != 2 + n + 4 * q:
        return None
    initial = list(values[2:2 + n])
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in initial):
        return None
    current = initial.copy()
    operations: list[tuple[int, int, int, int]] = []
    cursor = 2 + n
    for _ in range(q):
        opcode, first, second, third = values[cursor:cursor + 4]
        cursor += 4
        if opcode == 0:
            if not 0 <= first < n or not MIN_VALUE <= second <= MAX_VALUE or third != 0:
                return None
            current[first] = second
        elif opcode == 1:
            if not 0 <= first < second <= n or not 1 <= third <= second - first:
                return None
        else:
            return None
        operations.append((opcode, first, second, third))
    return initial, operations


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return I64_MIN
    initial, operations = decoded
    n = len(initial)
    left_child = [0] * NODE_CAPACITY
    right_child = [0] * NODE_CAPACITY
    count = [0] * NODE_CAPACITY
    roots = [0] * (n + 1)
    used = 0

    def change(root: int, low: int, high: int, coordinate: int, delta: int) -> int:
        nonlocal used
        if root == 0:
            used += 1
            if used >= NODE_CAPACITY:
                raise AssertionError("proven node capacity exceeded")
            root = used
        count[root] += delta
        if high - low > 1:
            middle = (low + high) // 2
            if coordinate < middle:
                left_child[root] = change(left_child[root], low, middle, coordinate, delta)
            else:
                right_child[root] = change(right_child[root], middle, high, coordinate, delta)
        return root

    def apply(position: int, value: int, delta: int) -> None:
        node = position + 1
        coordinate = value - MIN_VALUE
        while node <= n:
            roots[node] = change(roots[node], 0, VALUE_COUNT, coordinate, delta)
            node += node & -node

    current = initial.copy()
    for position, value in enumerate(current):
        apply(position, value, 1)

    result = 0
    query_ordinal = 0
    for opcode, first, second, third in operations:
        if opcode == 0:
            apply(first, current[first], -1)
            current[first] = second
            apply(first, second, 1)
            continue

        left_roots: list[int] = []
        right_roots: list[int] = []
        node = first
        while node:
            left_roots.append(roots[node])
            node -= node & -node
        node = second
        while node:
            right_roots.append(roots[node])
            node -= node & -node

        low, high, rank = 0, VALUE_COUNT, third
        while high - low > 1:
            middle = (low + high) // 2
            left_total = sum(count[left_child[root]] for root in right_roots)
            left_total -= sum(count[left_child[root]] for root in left_roots)
            if rank <= left_total:
                right_roots = [left_child[root] for root in right_roots]
                left_roots = [left_child[root] for root in left_roots]
                high = middle
            else:
                rank -= left_total
                right_roots = [right_child[root] for root in right_roots]
                left_roots = [right_child[root] for root in left_roots]
                low = middle
        answer = low + MIN_VALUE
        query_ordinal += 1
        result += query_ordinal * answer
    return result
