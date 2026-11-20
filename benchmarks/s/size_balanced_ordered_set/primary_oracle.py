"""Subtree-size-balanced ordered set and operation checksum."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_OPERATIONS = 128
MAX_KEY = 1023
MIN_KEY = -1024
NO_KEY = -1025
MAX_VALID_INPUT_LENGTH = 257
MAX_PARSEABLE_INPUT_LENGTH = 258
WORKSPACE_BYTES = 8192


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
    operation_count = values[0]
    if len(values) != 1 + 2 * operation_count:
        return None
    operations = []
    for index in range(operation_count):
        operation, argument = values[1 + 2 * index:3 + 2 * index]
        if operation not in range(5):
            return None
        if operation == 2:
            if not 0 <= argument < MAX_OPERATIONS:
                return None
        elif not MIN_KEY <= argument <= MAX_KEY:
            return None
        operations.append((operation, argument))
    return operations


def _tree_checksum(operations: list[tuple[int, int]]) -> int:
    # Index zero is the null child. Nodes are allocated once per successful
    # distinct insertion; the operation limit bounds this arena to 129 slots.
    keys = [0] * (MAX_OPERATIONS + 1)
    left = [0] * (MAX_OPERATIONS + 1)
    right = [0] * (MAX_OPERATIONS + 1)
    sizes = [0] * (MAX_OPERATIONS + 1)
    allocated = 0

    def update(node: int) -> None:
        sizes[node] = sizes[left[node]] + sizes[right[node]] + 1

    def rotate_left(node: int) -> int:
        successor = right[node]
        right[node] = left[successor]
        left[successor] = node
        update(node)
        update(successor)
        return successor

    def rotate_right(node: int) -> int:
        successor = left[node]
        left[node] = right[successor]
        right[successor] = node
        update(node)
        update(successor)
        return successor

    def maintain(node: int) -> int:
        if node == 0:
            return 0
        left_node = left[node]
        right_node = right[node]
        if left_node and sizes[left[left_node]] > sizes[right_node]:
            node = rotate_right(node)
            right[node] = maintain(right[node])
            return maintain(node)
        if left_node and sizes[right[left_node]] > sizes[right_node]:
            left[node] = rotate_left(left_node)
            node = rotate_right(node)
            left[node] = maintain(left[node])
            right[node] = maintain(right[node])
            return maintain(node)
        if right_node and sizes[right[right_node]] > sizes[left_node]:
            node = rotate_left(node)
            left[node] = maintain(left[node])
            return maintain(node)
        if right_node and sizes[left[right_node]] > sizes[left_node]:
            right[node] = rotate_right(right_node)
            node = rotate_left(node)
            left[node] = maintain(left[node])
            right[node] = maintain(right[node])
            return maintain(node)
        return node

    def insert(node: int, key: int) -> int:
        nonlocal allocated
        if node == 0:
            allocated += 1
            keys[allocated] = key
            sizes[allocated] = 1
            return allocated
        if key == keys[node]:
            return node
        if key < keys[node]:
            left[node] = insert(left[node], key)
        else:
            right[node] = insert(right[node], key)
        update(node)
        return maintain(node)

    def rank(node: int, key: int) -> int:
        answer = 0
        while node:
            if key <= keys[node]:
                node = left[node]
            else:
                answer += sizes[left[node]] + 1
                node = right[node]
        return answer

    def kth(node: int, index: int) -> int:
        if index >= sizes[node]:
            return NO_KEY
        while node:
            left_size = sizes[left[node]]
            if index < left_size:
                node = left[node]
            elif index == left_size:
                return keys[node]
            else:
                index -= left_size + 1
                node = right[node]
        return NO_KEY

    def predecessor(node: int, key: int) -> int:
        answer = NO_KEY
        while node:
            if keys[node] < key:
                answer = keys[node]
                node = right[node]
            else:
                node = left[node]
        return answer

    def successor(node: int, key: int) -> int:
        answer = NO_KEY
        while node:
            if keys[node] > key:
                answer = keys[node]
                node = left[node]
            else:
                node = right[node]
        return answer

    root = 0
    checksum = 0
    for step, (operation, argument) in enumerate(operations, start=1):
        if operation == 0:
            root = insert(root, argument)
            continue
        if operation == 1:
            answer = rank(root, argument)
        elif operation == 2:
            answer = kth(root, argument)
        elif operation == 3:
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
