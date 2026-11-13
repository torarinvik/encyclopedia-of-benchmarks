"""Bounded order-statistic AVL tree for the Library Checker ordered-set API."""

from __future__ import annotations

from collections.abc import Sequence

MAX_ITEMS = 32
MAX_OPERATIONS = 32
MAX_KEY = 1_000
MAX_LIVE_KEYS = 64
MAX_VALID_INPUT_LENGTH = 98
MAX_PARSEABLE_INPUT_LENGTH = 99
INVALID_RESULT = -1
WORKSPACE_BYTES = 8192
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

SOURCE = "https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/ordered_set/task.md"


class _Node:
    __slots__ = ("key", "height", "size", "left", "right")

    def __init__(self, key: int) -> None:
        self.key = key
        self.height = 1
        self.size = 1
        self.left: _Node | None = None
        self.right: _Node | None = None


def _height(node: _Node | None) -> int:
    return 0 if node is None else node.height


def _size(node: _Node | None) -> int:
    return 0 if node is None else node.size


def _refresh(node: _Node) -> None:
    node.height = max(_height(node.left), _height(node.right)) + 1
    node.size = _size(node.left) + _size(node.right) + 1


def _rotate_right(root: _Node) -> _Node:
    pivot = root.left
    assert pivot is not None
    root.left = pivot.right
    pivot.right = root
    _refresh(root)
    _refresh(pivot)
    return pivot


def _rotate_left(root: _Node) -> _Node:
    pivot = root.right
    assert pivot is not None
    root.right = pivot.left
    pivot.left = root
    _refresh(root)
    _refresh(pivot)
    return pivot


def _balance(root: _Node) -> _Node:
    _refresh(root)
    difference = _height(root.left) - _height(root.right)
    if difference > 1:
        assert root.left is not None
        if _height(root.left.left) < _height(root.left.right):
            root.left = _rotate_left(root.left)
        return _rotate_right(root)
    if difference < -1:
        assert root.right is not None
        if _height(root.right.right) < _height(root.right.left):
            root.right = _rotate_right(root.right)
        return _rotate_left(root)
    return root


def _insert(root: _Node | None, key: int) -> _Node:
    if root is None:
        return _Node(key)
    if key < root.key:
        root.left = _insert(root.left, key)
    elif key > root.key:
        root.right = _insert(root.right, key)
    else:
        return root
    return _balance(root)


def _minimum(root: _Node) -> _Node:
    while root.left is not None:
        root = root.left
    return root


def _erase(root: _Node | None, key: int) -> _Node | None:
    if root is None:
        return None
    if key < root.key:
        root.left = _erase(root.left, key)
    elif key > root.key:
        root.right = _erase(root.right, key)
    elif root.left is None:
        return root.right
    elif root.right is None:
        return root.left
    else:
        successor = _minimum(root.right)
        root.key = successor.key
        root.right = _erase(root.right, successor.key)
    return _balance(root)


def _kth(root: _Node | None, rank: int) -> int:
    if rank < 1 or rank > _size(root):
        return -1
    while root is not None:
        left_size = _size(root.left)
        if rank == left_size + 1:
            return root.key
        if rank <= left_size:
            root = root.left
        else:
            rank -= left_size + 1
            root = root.right
    return -1


def _count_le(root: _Node | None, key: int) -> int:
    count = 0
    while root is not None:
        if root.key <= key:
            count += _size(root.left) + 1
            root = root.right
        else:
            root = root.left
    return count


def _predecessor(root: _Node | None, key: int) -> int:
    answer = -1
    while root is not None:
        if root.key <= key:
            answer = root.key
            root = root.right
        else:
            root = root.left
    return answer


def _successor(root: _Node | None, key: int) -> int:
    answer = -1
    while root is not None:
        if root.key >= key:
            answer = root.key
            root = root.left
        else:
            root = root.right
    return answer


def _decode(
    values: Sequence[int] | None,
    input_is_null: bool,
    input_length: int | None,
) -> tuple[list[int], list[tuple[int, int]]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    actual_length = len(values)
    if input_length is None:
        input_length = actual_length
    if (
        type(input_length) is not int
        or input_length != actual_length
        or actual_length < 2
        or actual_length > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None
    initial_count, operation_count = values[0], values[1]
    if not 0 <= initial_count <= MAX_ITEMS or not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    if actual_length != 2 + initial_count + 2 * operation_count:
        return None
    initial = list(values[2 : 2 + initial_count])
    if any(not 0 <= key <= MAX_KEY for key in initial):
        return None
    if any(initial[index - 1] >= initial[index] for index in range(1, len(initial))):
        return None
    operations: list[tuple[int, int]] = []
    offset = 2 + initial_count
    for index in range(operation_count):
        opcode, key = values[offset + 2 * index : offset + 2 * index + 2]
        if opcode not in (0, 1, 2, 3, 4, 5) or not 0 <= key <= MAX_KEY:
            return None
        if opcode == 2 and key < 1:
            return None
        operations.append((opcode, key))
    return initial, operations


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Return the weighted checksum of order-statistic query answers."""
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT
    initial, operations = decoded
    root: _Node | None = None
    for key in initial:
        root = _insert(root, key)
    checksum = 0
    query_index = 0
    for opcode, key in operations:
        if opcode == 0:
            root = _insert(root, key)
        elif opcode == 1:
            root = _erase(root, key)
        else:
            if opcode == 2:
                answer = _kth(root, key)
            elif opcode == 3:
                answer = _count_le(root, key)
            elif opcode == 4:
                answer = _predecessor(root, key)
            else:
                answer = _successor(root, key)
            query_index += 1
            checksum += query_index * (answer + 1)
    return checksum
