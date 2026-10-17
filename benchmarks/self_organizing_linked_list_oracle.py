"""Oracle for the bounded Java move-to-front linked-list byte trace."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_OPERATION_COUNT = 64
MAX_LIST_LENGTH = 64
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_OPERATION_COUNT
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_FIELDS = 2 + 3 * MAX_OPERATION_COUNT
MAX_OUTPUT_BYTES = MAX_OUTPUT_FIELDS * 8
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return ``(result, output_bytes)`` for a trace and output-buffer shape."""
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
    if (
        (input_length is not None and input_length != len(values))
        or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(
            type(value) is not int or not I64_MIN <= value <= I64_MAX
            for value in values
        )
    ):
        return INVALID_RESULT, b""

    operation_count = values[0]
    if (
        not 0 <= operation_count <= MAX_OPERATION_COUNT
        or len(values) != 1 + 2 * operation_count
    ):
        return INVALID_RESULT, b""

    items: list[int] = []
    output_fields: list[int] = []
    cursor = 1
    for _ in range(operation_count):
        opcode, value = values[cursor : cursor + 2]
        cursor += 2
        if not I32_MIN <= value <= I32_MAX:
            return INVALID_RESULT, b""

        if opcode == 0:
            if len(items) >= MAX_LIST_LENGTH:
                return INVALID_RESULT, b""
            items.append(value)
            output_fields.extend((0, 0))
        elif opcode == 1:
            try:
                found_at = items.index(value)
            except ValueError:
                found = 0
            else:
                found = 1
                if found_at != 0:
                    items.insert(0, items.pop(found_at))
            output_fields.extend((1, 1, found))
        else:
            return INVALID_RESULT, b""

    output_fields.extend((2, len(items), *items))
    if len(output_fields) > MAX_OUTPUT_FIELDS:
        return INVALID_RESULT, b""
    output = struct.pack("<" + "q" * len(output_fields), *output_fields)

    if output_is_null or (
        output_capacity is not None and output_capacity < len(output)
    ):
        return OUTPUT_ERROR, b""
    return len(output), output
