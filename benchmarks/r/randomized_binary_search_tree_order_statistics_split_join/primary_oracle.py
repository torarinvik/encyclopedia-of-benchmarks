"""Martínez–Roura randomized-BST reference for the bounded operation trace."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INITIAL = 32
MAX_OPERATIONS = 32
MAX_VALID_INPUT_LENGTH = 163
MAX_PARSEABLE_INPUT_LENGTH = 164
WORKSPACE_BYTES = 8192
MAX_KEY = 1000
MAX_RANK = 65
U32_MASK = (1 << 32) - 1
U32_RANGE = 1 << 32
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


class _Node:
    __slots__ = ("key", "left", "right", "size")

    def __init__(self, key: int, left: _Node | None = None, right: _Node | None = None):
        self.key = key
        self.left = left
        self.right = right
        self.size = 1 + _size(left) + _size(right)


def _size(root: _Node | None) -> int:
    return 0 if root is None else root.size


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[int, list[int], list[tuple[int, int, int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    initial_count, operation_count, seed = values[:3]
    if not 0 <= initial_count <= MAX_INITIAL or not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    if not 0 <= seed <= U32_MASK:
        return None
    expected_length = 3 + initial_count + 4 * operation_count
    if len(values) != expected_length:
        return None
    initial = list(values[3:3 + initial_count])
    if any(not 0 <= key <= MAX_KEY for key in initial):
        return None
    if any(first >= second for first, second in zip(initial, initial[1:])):
        return None

    operations: list[tuple[int, int, int, int]] = []
    offset = 3 + initial_count
    for operation_index in range(operation_count):
        opcode, a, b, c = values[offset + 4 * operation_index:offset + 4 * operation_index + 4]
        if opcode in (0, 1):
            if a not in (0, 1) or not 0 <= b <= MAX_KEY or c != 0:
                return None
        elif opcode == 2:
            if a not in (0, 1) or not 1 <= b <= MAX_RANK or c != 0:
                return None
        elif opcode == 3:
            if a not in (0, 1) or b not in (0, 1) or a == b or not 0 <= c <= MAX_KEY + 1:
                return None
        elif opcode == 4:
            if a not in (0, 1) or b not in (0, 1) or a == b or c != 0:
                return None
        else:
            return None
        operations.append((opcode, a, b, c))
    return seed, initial, operations


class _RandomSource:
    __slots__ = ("state",)

    def __init__(self, seed: int):
        self.state = seed

    def below(self, bound: int) -> int:
        threshold = U32_RANGE % bound
        while True:
            self.state = (1664525 * self.state + 1013904223) & U32_MASK
            if self.state >= threshold:
                return self.state % bound


def _split(root: _Node | None, pivot: int) -> tuple[_Node | None, _Node | None]:
    if root is None:
        return None, None
    if root.key < pivot:
        low, high = _split(root.right, pivot)
        root.right = low
        root.size = 1 + _size(root.left) + _size(root.right)
        return root, high
    low, high = _split(root.left, pivot)
    root.left = high
    root.size = 1 + _size(root.left) + _size(root.right)
    return low, root


def _join(left: _Node | None, right: _Node | None,
          random: _RandomSource) -> _Node | None:
    if left is None:
        return right
    if right is None:
        return left
    total = left.size + right.size
    if random.below(total) < left.size:
        left.right = _join(left.right, right, random)
        left.size = 1 + _size(left.left) + _size(left.right)
        return left
    right.left = _join(left, right.left, random)
    right.size = 1 + _size(right.left) + _size(right.right)
    return right


def _contains(root: _Node | None, key: int) -> bool:
    while root is not None:
        if key == root.key:
            return True
        root = root.left if key < root.key else root.right
    return False


def _insert_absent(root: _Node | None, key: int,
                   random: _RandomSource) -> _Node:
    if root is None:
        return _Node(key)
    if random.below(root.size + 1) == 0:
        left, right = _split(root, key)
        return _Node(key, left, right)
    if key < root.key:
        root.left = _insert_absent(root.left, key, random)
    else:
        root.right = _insert_absent(root.right, key, random)
    root.size = 1 + _size(root.left) + _size(root.right)
    return root


def _erase(root: _Node | None, key: int,
           random: _RandomSource) -> _Node | None:
    if root is None:
        return None
    if key == root.key:
        return _join(root.left, root.right, random)
    if key < root.key:
        root.left = _erase(root.left, key, random)
    else:
        root.right = _erase(root.right, key, random)
    root.size = 1 + _size(root.left) + _size(root.right)
    return root


def _kth(root: _Node | None, rank: int) -> int:
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


def _minimum(root: _Node | None) -> int | None:
    if root is None:
        return None
    while root.left is not None:
        root = root.left
    return root.key


def _maximum(root: _Node | None) -> int | None:
    if root is None:
        return None
    while root.right is not None:
        root = root.right
    return root.key


def _run(seed: int, initial: list[int],
         operations: list[tuple[int, int, int, int]]) -> int:
    random = _RandomSource(seed)
    roots: list[_Node | None] = [None, None]
    for key in initial:
        roots[0] = _insert_absent(roots[0], key, random)

    checksum = 0
    query_index = 0
    for opcode, a, b, c in operations:
        if opcode == 0:
            if not _contains(roots[a], b):
                roots[a] = _insert_absent(roots[a], b, random)
        elif opcode == 1:
            roots[a] = _erase(roots[a], b, random)
        elif opcode == 2:
            query_index += 1
            answer = _kth(roots[a], b)
            checksum += query_index * (answer + 1)
        elif opcode == 3:
            if roots[b] is not None:
                return -1
            roots[a], roots[b] = _split(roots[a], c)
        else:
            left_max = _maximum(roots[a])
            right_min = _minimum(roots[b])
            if left_max is not None and right_min is not None and left_max >= right_min:
                return -1
            roots[a] = _join(roots[a], roots[b], random)
            roots[b] = None
    return checksum


def expected_result(values: Sequence[int] | None, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    """Return the weighted kth-query checksum or -1 for an invalid trace."""
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1
    return _run(*parsed)
