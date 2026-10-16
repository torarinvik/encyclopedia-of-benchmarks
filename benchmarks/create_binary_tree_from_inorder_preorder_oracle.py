"""Independent oracle for tree reconstruction from preorder and inorder."""

from __future__ import annotations

import struct

MAX_NODES = 63
MAX_INPUT_LENGTH = 1 + 2 * MAX_NODES
MAX_OUTPUT_BYTES = 1 + 6 * MAX_NODES
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY = -2


def expected_output(values: tuple[int, ...] | list[int],
                    capacity: int | None = None) -> tuple[int, bytes]:
    """Reconstruct the uniquely specified tree and emit preorder node records."""
    if (not isinstance(values, (tuple, list)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return INVALID_RESULT, b""
    node_count = values[0]
    if (not 0 <= node_count <= MAX_NODES or len(values) != 1 + 2 * node_count):
        return INVALID_RESULT, b""
    preorder = list(values[1:1 + node_count])
    inorder = list(values[1 + node_count:])
    if (any(not -(2**31) <= value <= 2**31 - 1 for value in preorder + inorder)
            or len(set(preorder)) != node_count
            or len(set(inorder)) != node_count
            or set(preorder) != set(inorder)):
        return INVALID_RESULT, b""

    preorder_index = 0

    def serialize(start: int, end: int) -> bytes:
        nonlocal preorder_index
        if start == end:
            return b"\0"
        if preorder_index >= node_count:
            raise ValueError("preorder ended before the inorder interval")
        value = preorder[preorder_index]
        preorder_index += 1
        try:
            root_position = inorder.index(value, start, end)
        except ValueError as error:
            raise ValueError("preorder root is absent from the inorder interval") from error
        return (b"\1" + struct.pack("<i", value)
                + serialize(start, root_position)
                + serialize(root_position + 1, end))

    try:
        output = serialize(0, node_count)
    except ValueError:
        return INVALID_RESULT, b""
    if preorder_index != node_count:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if capacity is not None and len(output) > capacity:
        return INSUFFICIENT_CAPACITY, b""
    return node_count, output
