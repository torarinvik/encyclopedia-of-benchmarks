"""Oracle for the shared observable subset of Java and Python splay trees."""

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
INSERT_RESULT = -2
DELETE_RESULT = -3


@dataclass
class _Node:
    key: int
    left: _Node | None = None
    right: _Node | None = None


def _rotate_right(node: _Node) -> _Node:
    left = node.left
    assert left is not None
    node.left = left.right
    left.right = node
    return left


def _rotate_left(node: _Node) -> _Node:
    right = node.right
    assert right is not None
    node.right = right.left
    right.left = node
    return right


def _splay(root: _Node | None, key: int) -> _Node | None:
    if root is None or root.key == key:
        return root
    if key < root.key:
        if root.left is None:
            return root
        if key < root.left.key:
            root.left.left = _splay(root.left.left, key)
            root = _rotate_right(root)
        elif key > root.left.key:
            root.left.right = _splay(root.left.right, key)
            if root.left.right is not None:
                root.left = _rotate_left(root.left)
        return root if root.left is None else _rotate_right(root)
    if root.right is None:
        return root
    if key > root.right.key:
        root.right.right = _splay(root.right.right, key)
        root = _rotate_left(root)
    elif key < root.right.key:
        root.right.left = _splay(root.right.left, key)
        if root.right.left is not None:
            root.right = _rotate_right(root.right)
    return root if root.right is None else _rotate_left(root)


def _insert(root: _Node | None, key: int) -> _Node:
    if root is None:
        return _Node(key)
    root = _splay(root, key)
    assert root is not None
    if root.key == key:
        raise ValueError("duplicate insert is outside the shared source contract")
    node = _Node(key)
    if key < root.key:
        node.right = root
        node.left = root.left
        root.left = None
    else:
        node.left = root
        node.right = root.right
        root.right = None
    return node


def _delete(root: _Node | None, key: int) -> _Node | None:
    if root is None:
        raise ValueError("delete from an empty tree is outside the shared source contract")
    root = _splay(root, key)
    assert root is not None
    if root.key != key:
        return root
    left, right = root.left, root.right
    if left is None:
        return right
    left = _splay(left, key)
    assert left is not None
    left.right = right
    return left


def _in_order(root: _Node | None) -> list[int]:
    if root is None:
        return []
    return [*_in_order(root.left), root.key, *_in_order(root.right)]


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
        if opcode not in (0, 1, 2) or not I32_MIN <= key <= I32_MAX:
            return None
        operations.append((opcode, key))
    return operations


def _run(operations: Sequence[tuple[int, int]]) -> tuple[list[int], list[int]] | None:
    live_keys: set[int] = set()
    for opcode, key in operations:
        if opcode == 0:
            if key in live_keys or len(live_keys) >= MAX_LIVE_KEYS:
                return None
            live_keys.add(key)
        elif opcode == 2:
            if not live_keys:
                return None
            live_keys.discard(key)

    root: _Node | None = None
    results: list[int] = []
    try:
        for opcode, key in operations:
            if opcode == 0:
                root = _insert(root, key)
                results.append(INSERT_RESULT)
            elif opcode == 1:
                root = _splay(root, key)
                results.append(1 if root is not None and root.key == key else 0)
            else:
                root = _delete(root, key)
                results.append(DELETE_RESULT)
    except ValueError:
        return None
    return results, _in_order(root)


def expected_result(values: Sequence[int] | None) -> bytes | None:
    """Return operation tags/results followed by the final in-order key list."""
    operations = _parse(values)
    if operations is None:
        return None
    run = _run(operations)
    if run is None:
        return None
    results, final_keys = run
    words = [len(results), *results, len(final_keys), *final_keys]
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
