"""Independent bounded oracle for the pinned TBC padding operations."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_BYTES = 256
MAX_INPUT_LENGTH = MAX_BYTES + 3
MAX_OUTPUT_BYTES = MAX_BYTES + 8
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int]) -> tuple[int, int, bytearray] | None:
    if (not isinstance(values, (list, tuple)) or len(values) < 3 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return None
    operation, offset, length = values[:3]
    if operation not in (0, 1, 2) or not 0 <= length <= MAX_BYTES or len(values) != length + 3:
        return None
    if any(value < 0 or value > 255 for value in values[3:]):
        return None
    if operation == 0:
        if length == 0 or not 0 <= offset <= length:
            return None
    elif offset != 0:
        return None
    elif operation == 2 and length == 0:
        return None
    return operation, offset, bytearray(values[3:])


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return (bytes-written/status, output) for the selected operation."""
    parsed = _parse(values)
    if parsed is None:
        return INVALID_RESULT, b""
    operation, offset, data = parsed

    if operation == 0:
        last_bit = (data[offset - 1] if offset > 0 else data[-1]) & 1
        code = 0xFF if last_bit == 0 else 0x00
        pad_count = len(data) - offset
        data[offset:] = bytes([code]) * pad_count
        output = struct.pack("<q", pad_count) + data
    elif operation == 1:
        if data:
            code = 0x00 if data[-1] & 1 == 0 else 0xFF
            end = len(data)
            while end > 0 and data[end - 1] == code:
                end -= 1
            data = data[:end]
        output = bytes(data)
    else:
        terminal = data[-1]
        if terminal not in (0x00, 0xFF):
            return INVALID_RESULT, b""
        count = 0
        for value in reversed(data):
            if value != terminal:
                break
            count += 1
        output = struct.pack("<q", count)

    if type(output_capacity) is not int or output_capacity < 0:
        return INVALID_RESULT, b""
    if output_is_null or output_capacity < len(output):
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(output), bytes(output)
