"""Independent bounded oracle for Morris inorder traversal output."""

from __future__ import annotations

import struct
from collections.abc import Sequence

I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_NODE_COUNT = 63
MAX_VALID_INPUT_LENGTH = 1 + MAX_NODE_COUNT
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_PARSEABLE_INPUT_VALUES = MAX_INPUT_LENGTH
MAX_OUTPUT_BYTES = 4 * MAX_NODE_COUNT
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return (byte count, inorder bytes), or the bounded ABI sentinel."""
    if type(input_is_null) is not bool or type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT, b""

    node_count = values[0]
    if not 0 <= node_count <= MAX_NODE_COUNT or len(values) != node_count + 1:
        return INVALID_RESULT, b""
    nodes = values[1:]
    if any(not I32_MIN <= node <= I32_MAX for node in nodes):
        return INVALID_RESULT, b""
    if type(output_capacity) is not int or output_capacity < 0:
        return INVALID_RESULT, b""
    if output_is_null or output_capacity < 4 * node_count:
        return OUTPUT_ERROR_RESULT, b""

    ordered: list[int] = []

    def inorder(index: int) -> None:
        if index >= node_count:
            return
        inorder(2 * index + 1)
        ordered.append(nodes[index])
        inorder(2 * index + 2)

    inorder(0)
    output = b"".join(struct.pack("<i", node) for node in ordered)
    return len(output), output
