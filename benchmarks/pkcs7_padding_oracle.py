"""Independent bounded oracle for the selected PKCS#7 padding methods."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2
MAX_BLOCK_SIZE = 16
MAX_BUFFER_LENGTH = 64
MAX_INPUT_LENGTH = 4 + MAX_BUFFER_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_BUFFER_LENGTH + 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(
    values: Sequence[int] | None,
    output_capacity: int,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the ABI result and bytes for add, remove, or count operations."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    if (not isinstance(values, (list, tuple))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or len(values) < 5
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT, b""

    operation, block_size, input_offset, data_length = values[:4]
    data_values = values[4:]
    if (operation not in (0, 1, 2)
            or not 1 <= block_size <= MAX_BLOCK_SIZE
            or not 1 <= data_length <= MAX_BUFFER_LENGTH
            or len(data_values) != data_length
            or (operation == 0 and not 0 <= input_offset <= data_length)
            or any(value < 0 or value > 255 for value in data_values)):
        return INVALID_RESULT, b""
    data = bytes(data_values)

    if operation == 0:
        padding_count = block_size - (data_length % block_size)
        if padding_count == 0:
            padding_count = block_size
        if input_offset + padding_count > data_length:
            return INVALID_RESULT, b""
        modified = bytearray(data)
        modified[input_offset:input_offset + padding_count] = bytes([padding_count]) * padding_count
        output = bytes([padding_count]) + bytes(modified)
    elif operation == 1:
        if data_length % block_size != 0:
            return INVALID_RESULT, b""
        padding_count = data[-1]
        if not 1 <= padding_count <= block_size:
            return INVALID_RESULT, b""
        if data[-padding_count:] != bytes([padding_count]) * padding_count:
            return INVALID_RESULT, b""
        output = data[:-padding_count]
    else:
        padding_count = data[-1]
        padding_start = data_length - padding_count
        padding_check_failed = (padding_start | (padding_count - 1)) >> 31
        for index, value in enumerate(data):
            mask = ~((index - padding_start) >> 31)
            padding_check_failed |= (value ^ padding_count) & mask
        if padding_check_failed != 0:
            return INVALID_RESULT, b""
        output = bytes([padding_count])

    if output_is_null or output_capacity < len(output):
        return OUTPUT_ERROR_RESULT, b""
    return len(output), output
