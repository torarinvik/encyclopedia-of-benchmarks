"""Oracle for the pinned slow/fast-pointer middle-node operation."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_NODES = 128
MAX_INPUT_LENGTH = 1 + MAX_NODES
OUTPUT_BYTES = 8
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the selected node identity as ``[found, index]`` or an ABI status."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT, b""

    node_count = values[0]
    if not 0 <= node_count <= MAX_NODES or len(values) != node_count + 1:
        return INVALID_RESULT, b""
    nodes = values[1:]
    if any(not I32_MIN <= value <= I32_MAX for value in nodes):
        return INVALID_RESULT, b""

    if node_count == 0:
        output = struct.pack("<ii", 0, -1)
    else:
        output = struct.pack("<ii", 1, node_count // 2)
    if output_is_null or (
        output_capacity is not None and output_capacity < OUTPUT_BYTES
    ):
        return OUTPUT_ERROR, b""
    return OUTPUT_BYTES, output
