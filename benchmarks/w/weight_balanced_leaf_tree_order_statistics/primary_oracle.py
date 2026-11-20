"""Merge-based weight-balanced leaf tree operation checksum."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_OPERATIONS = 64
MIN_KEY = -128
MAX_KEY = 127
NO_KEY = -129
MAX_VALID_INPUT_LENGTH = 129
MAX_PARSEABLE_INPUT_LENGTH = 130
WORKSPACE_BYTES = 16384
NODE_CAPACITY = 2 * MAX_OPERATIONS + 1


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if not values or not 0 <= values[0] <= MAX_OPERATIONS:
        return None
    count = values[0]
    if len(values) != 1 + 2 * count:
        return None
    operations = []
    for index in range(count):
        operation, argument = values[1 + 2 * index:3 + 2 * index]
        if operation not in range(6):
            return None
        if operation == 3:
            if not 0 <= argument < MAX_OPERATIONS:
                return None
        elif not MIN_KEY <= argument <= MAX_KEY:
            return None
        operations.append((operation, argument))
    return operations


def _tree_checksum(operations: list[tuple[int, int]]) -> int:
    left = [0] * NODE_CAPACITY
    right = [0] * NODE_CAPACITY
    size = [0] * NODE_CAPACITY
    key = [0] * NODE_CAPACITY
    maximum = [0] * NODE_CAPACITY
    free_next = [0] * NODE_CAPACITY
    next_node = 1
    free_head = 0

    def allocate() -> int:
        nonlocal next_node, free_head
        if free_head:
            node = free_head
            free_head = free_next[node]
        else:
            node = next_node
            next_node += 1
        return node

    def release(node: int) -> None:
        nonlocal free_head
        left[node] = right[node] = size[node] = key[node] = maximum[node] = 0
        free_next[node] = free_head
        free_head = node

    def leaf(value: int) -> int:
        node = allocate()
        key[node] = maximum[node] = value
        size[node] = 1
        return node

    def join(a: int, b: int) -> int:
        node = allocate()
        left[node], right[node] = a, b
        size[node] = size[a] + size[b]
        maximum[node] = maximum[b]
        return node

    def cut(node: int) -> tuple[int, int]:
        a, b = left[node], right[node]
        release(node)
        return a, b

    def too_heavy(a: int, b: int) -> bool:
        return a > 3 * b

    def rebalance(node: int) -> int:
        if size[node] == 1:
            return node
        a, b = left[node], right[node]
        if too_heavy(size[a], size[b]) or too_heavy(size[b], size[a]):
            a, b = cut(node)
            return merge(a, b)
        return node

    def merge(a: int, b: int) -> int:
        if not a:
            return b
        if not b:
            return a
        if too_heavy(size[a], size[b]):
            x, y = cut(a)
            return rebalance(join(x, merge(y, b)))
        if too_heavy(size[b], size[a]):
            x, y = cut(b)
            return rebalance(join(merge(a, x), y))
        return join(a, b)

    def insert(node: int, value: int) -> int:
        if not node:
            return leaf(value)
        if size[node] == 1:
            if value <= key[node]:
                return join(leaf(value), node)
            return join(node, leaf(value))
        if value <= maximum[left[node]]:
            left[node] = insert(left[node], value)
        else:
            right[node] = insert(right[node], value)
        size[node] = size[left[node]] + size[right[node]]
        maximum[node] = maximum[right[node]]
        return rebalance(node)

    def remove(node: int, value: int) -> tuple[int, bool]:
        if not node:
            return 0, False
        if size[node] == 1:
            if key[node] == value:
                release(node)
                return 0, True
            return node, False
        if value <= maximum[left[node]]:
            left[node], removed = remove(left[node], value)
        else:
            right[node], removed = remove(right[node], value)
        if not removed:
            return node, False
        if not left[node] or not right[node]:
            child = left[node] or right[node]
            release(node)
            return child, True
        size[node] = size[left[node]] + size[right[node]]
        maximum[node] = maximum[right[node]]
        return rebalance(node), True

    def rank(node: int, value: int) -> int:
        if not node or size[node] == 1:
            return int(bool(node and key[node] < value))
        a = left[node]
        return rank(a, value) if value <= maximum[a] else size[a] + rank(right[node], value)

    def kth(node: int, index: int) -> int:
        if not node or index >= size[node]:
            return NO_KEY
        if size[node] == 1:
            return key[node]
        a = left[node]
        return kth(a, index) if index < size[a] else kth(right[node], index - size[a])

    def predecessor(node: int, value: int) -> int:
        if not node:
            return NO_KEY
        if size[node] == 1:
            return key[node] if key[node] < value else NO_KEY
        a, b = left[node], right[node]
        if value <= maximum[a]:
            return predecessor(a, value)
        answer = predecessor(b, value)
        return maximum[a] if answer == NO_KEY else answer

    def successor(node: int, value: int) -> int:
        if not node:
            return NO_KEY
        if size[node] == 1:
            return key[node] if key[node] > value else NO_KEY
        a, b = left[node], right[node]
        return successor(a, value) if value < maximum[a] else successor(b, value)

    root = 0
    checksum = 0
    for step, (operation, argument) in enumerate(operations, start=1):
        if operation == 0:
            root = insert(root, argument)
        elif operation == 1:
            root, _ = remove(root, argument)
        else:
            if operation == 2:
                answer = rank(root, argument)
            elif operation == 3:
                answer = kth(root, argument)
            elif operation == 4:
                answer = predecessor(root, argument)
            else:
                answer = successor(root, argument)
            checksum += step * (answer - NO_KEY)
    return checksum


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    operations = _decode(values, input_is_null, input_length)
    if operations is None:
        return -1
    return _tree_checksum(operations)
