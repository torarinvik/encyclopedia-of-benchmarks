"""Oracle for the bounded pinned Java two-list merge trace."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_NODES = 128
MAX_INPUT_LENGTH = 2 + MAX_NODES
MAX_OUTPUT_BYTES = 12 * MAX_NODES
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
    """Return merged provenance triples or the adapter's ABI status."""
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
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT, b""

    left_length = values[0]
    if not 0 <= left_length <= MAX_NODES or left_length + 1 >= len(values):
        return INVALID_RESULT, b""
    left_start = 1
    left_end = left_start + left_length
    right_length = values[left_end]
    if not 0 <= right_length <= MAX_NODES:
        return INVALID_RESULT, b""
    right_start = left_end + 1
    right_end = right_start + right_length
    if left_length + right_length > MAX_NODES or right_end != len(values):
        return INVALID_RESULT, b""

    left = values[left_start:left_end]
    right = values[right_start:right_end]
    for items in (left, right):
        if any(not I32_MIN <= value <= I32_MAX for value in items):
            return INVALID_RESULT, b""
        if any(items[index - 1] > items[index] for index in range(1, len(items))):
            return INVALID_RESULT, b""

    records: list[tuple[int, int, int]] = []
    left_index = 0
    right_index = 0
    while left_index < left_length and right_index < right_length:
        if left[left_index] <= right[right_index]:
            records.append((left[left_index], 0, left_index))
            left_index += 1
        else:
            records.append((right[right_index], 1, right_index))
            right_index += 1
    while left_index < left_length:
        records.append((left[left_index], 0, left_index))
        left_index += 1
    while right_index < right_length:
        records.append((right[right_index], 1, right_index))
        right_index += 1

    output = b"".join(struct.pack("<iii", *record) for record in records)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(output)
    ):
        return OUTPUT_ERROR, b""
    return len(output), output
