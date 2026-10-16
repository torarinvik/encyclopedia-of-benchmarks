"""Oracle for the bounded signed-i32 Stalin sort contract."""

from __future__ import annotations

import struct

INVALID_RESULT = -1
CAPACITY_ERROR_RESULT = -2
MAX_INPUT_LENGTH = 128
MAX_PARSEABLE_INPUT_LENGTH = 129
OUTPUT_BYTES_PER_VALUE = 4
WORKSPACE_BYTES = MAX_INPUT_LENGTH * OUTPUT_BYTES_PER_VALUE
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def sorted_values(values: list[int] | tuple[int, ...]) -> tuple[int, ...] | None:
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return None
    if len(values) > MAX_INPUT_LENGTH or any(not I32_MIN <= value <= I32_MAX for value in values):
        return None

    kept: list[int] = []
    for value in values:
        if not kept or value >= kept[-1]:
            kept.append(value)
    return tuple(kept)


def expected_output(
    values: list[int] | tuple[int, ...], output_capacity: int = WORKSPACE_BYTES
) -> tuple[int, bytes]:
    result = sorted_values(values)
    if result is None:
        return INVALID_RESULT, b""
    output_bytes = len(result) * OUTPUT_BYTES_PER_VALUE
    if type(output_capacity) is not int or output_capacity < output_bytes:
        return CAPACITY_ERROR_RESULT, b""
    if not result:
        return 0, b""
    return output_bytes, struct.pack(f"<{len(result)}i", *result)
