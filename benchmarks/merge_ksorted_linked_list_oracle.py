"""Oracle for the bounded pinned Java merge-k-sorted-linked-lists trace."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_LISTS = 16
MAX_NODES = 128
MAX_INPUT_LENGTH = 1 + MAX_LISTS + MAX_NODES
MAX_OUTPUT_BYTES = 4 * MAX_NODES
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
    """Return merged signed-i32 bytes or the adapter's ABI status."""
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

    list_count = values[0]
    if not 0 <= list_count <= MAX_LISTS:
        return INVALID_RESULT, b""

    position = 1
    total_nodes = 0
    merged: list[int] = []
    for _ in range(list_count):
        if position >= len(values):
            return INVALID_RESULT, b""
        list_length = values[position]
        position += 1
        if not 0 <= list_length <= MAX_NODES:
            return INVALID_RESULT, b""
        total_nodes += list_length
        if total_nodes > MAX_NODES or position + list_length > len(values):
            return INVALID_RESULT, b""
        current = values[position : position + list_length]
        if any(not I32_MIN <= value <= I32_MAX for value in current):
            return INVALID_RESULT, b""
        if any(current[index - 1] > current[index] for index in range(1, len(current))):
            return INVALID_RESULT, b""
        merged.extend(current)
        position += list_length
    if position != len(values):
        return INVALID_RESULT, b""

    merged.sort()
    output = b"".join(struct.pack("<i", value) for value in merged)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(output)
    ):
        return OUTPUT_ERROR, b""
    return len(output), output
