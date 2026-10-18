"""Oracle for the bounded default-alpha C# scapegoat tree trace."""

from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass
import struct

MAX_OPERATIONS = 64
MAX_LIVE_KEYS = 32
MAX_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (2 + MAX_OPERATIONS + MAX_LIVE_KEYS)
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2
CLEAR_RESULT = -2
ALPHA = 0.5


@dataclass
class _Node:
    key: int
    left: _Node | None = None
    right: _Node | None = None


def _size(node: _Node | None) -> int:
    if node is None:
        return 0
    return 1 + _size(node.left) + _size(node.right)


def _alpha_height(node: _Node) -> int:
    # The source uses floor(log(size, 1 / alpha)); alpha is fixed at 0.5.
    return _size(node).bit_length() - 1


def _flatten(node: _Node | None) -> list[int]:
    if node is None:
        return []
    return [*_flatten(node.left), node.key, *_flatten(node.right)]


def _rebuild(keys: Sequence[int], start: int = 0, end: int | None = None) -> _Node | None:
    if end is None:
        end = len(keys) - 1
    if start > end:
        return None
    # Extensions.RebuildFromList uses ceil(start + (end-start)/2.0), the
    # upper middle element for even-sized ranges.
    pivot = (start + end + 1) // 2
    return _Node(
        keys[pivot],
        _rebuild(keys, start, pivot - 1),
        _rebuild(keys, pivot + 1, end),
    )


def _find_scapegoat(path: list[_Node]) -> tuple[_Node | None, _Node]:
    depth = 1
    while path:
        node = path.pop()
        if depth > _alpha_height(node):
            parent = path.pop() if path else None
            return parent, node
        depth += 1
    raise ValueError("scapegoat was not found on an unbalanced insertion path")


class _ScapegoatTree:
    def __init__(self) -> None:
        self.root: _Node | None = None
        self.size = 0
        self.max_size = 0

    def _update_sizes(self) -> None:
        self.size += 1
        self.max_size = max(self.max_size, self.size)

    def contains(self, key: int) -> bool:
        node = self.root
        while node is not None:
            if key == node.key:
                return True
            node = node.left if key < node.key else node.right
        return False

    def insert(self, key: int) -> bool:
        if self.root is None:
            self.root = _Node(key)
            self._update_sizes()
            return True

        path: list[_Node] = []
        current = self.root
        while True:
            path.append(current)
            if key == current.key:
                return False
            if key < current.key:
                if current.left is None:
                    current.left = _Node(key)
                    break
                current = current.left
            else:
                if current.right is None:
                    current.right = _Node(key)
                    break
                current = current.right

        self._update_sizes()
        assert self.root is not None
        if len(path) > _alpha_height(self.root):
            parent, scapegoat = _find_scapegoat(path)
            rebuilt = _rebuild(_flatten(scapegoat))
            assert rebuilt is not None
            if parent is None:
                self.root = rebuilt
            elif parent.key < rebuilt.key:
                parent.right = rebuilt
            else:
                parent.left = rebuilt
            self.max_size = max(self.max_size, self.size)
        return True

    def _remove(self, node: _Node | None, key: int) -> tuple[_Node | None, bool]:
        if node is None:
            return None, False
        if key < node.key:
            node.left, found = self._remove(node.left, key)
            return node, found
        if key > node.key:
            node.right, found = self._remove(node.right, key)
            return node, found
        if node.left is None:
            return node.right, True
        if node.right is None:
            return node.left, True

        predecessor = node.left
        while predecessor.right is not None:
            predecessor = predecessor.right
        left, _ = self._remove(node.left, predecessor.key)
        return _Node(predecessor.key, left, node.right), True

    def delete(self, key: int) -> bool:
        self.root, found = self._remove(self.root, key)
        if not found:
            return False
        self.size -= 1
        if self.root is not None and 2 * self.size < self.max_size:
            self.root = _rebuild(_flatten(self.root))
            self.max_size = self.size
        return True

    def is_alpha_weight_balanced(self) -> bool:
        if self.root is None:
            return True
        total = _size(self.root)
        return 2 * _size(self.root.left) <= total and 2 * _size(self.root.right) <= total

    def clear(self) -> None:
        self.root = None
        self.size = 0
        self.max_size = 0


def _parse(values: Sequence[int] | None) -> list[tuple[int, int]] | None:
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return None
    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS or len(values) != 1 + 2 * operation_count:
        return None
    operations: list[tuple[int, int]] = []
    for offset in range(1, len(values), 2):
        opcode, key = values[offset : offset + 2]
        if opcode not in range(7) or not I32_MIN <= key <= I32_MAX:
            return None
        if opcode >= 3 and key != 0:
            return None
        operations.append((opcode, key))

    active: set[int] = set()
    for opcode, key in operations:
        if opcode == 0:
            if key not in active and len(active) >= MAX_LIVE_KEYS:
                return None
            active.add(key)
        elif opcode == 2:
            active.discard(key)
        elif opcode == 6:
            active.clear()
    return operations


def expected_result(values: Sequence[int] | None) -> bytes | None:
    """Return operation results followed by the final in-order key list."""
    operations = _parse(values)
    if operations is None:
        return None
    tree = _ScapegoatTree()
    results: list[int] = []
    for opcode, key in operations:
        if opcode == 0:
            results.append(1 if tree.insert(key) else 0)
        elif opcode == 1:
            results.append(1 if tree.contains(key) else 0)
        elif opcode == 2:
            results.append(1 if tree.delete(key) else 0)
        elif opcode == 3:
            results.append(tree.size)
        elif opcode == 4:
            results.append(tree.max_size)
        elif opcode == 5:
            results.append(1 if tree.is_alpha_weight_balanced() else 0)
        else:
            tree.clear()
            results.append(CLEAR_RESULT)
    words = [len(results), *results, tree.size, *_flatten(tree.root)]
    output = b"".join(struct.pack("<q", word) for word in words)
    return output if len(output) <= MAX_OUTPUT_BYTES else None


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return status and bytes for the signed-i64 array/byte-output ABI."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    output = expected_result(values)
    if output is None:
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
