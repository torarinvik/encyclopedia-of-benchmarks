"""Oracle for the pinned Misc/revertBits 32-bit and 64-bit reversals."""

from __future__ import annotations

import struct
from collections.abc import Sequence

U32_MAX = (1 << 32) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
OUTPUT_BYTES = 12
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _reverse32(value: int) -> int:
    value = ((value >> 1) & 0x55555555) | ((value & 0x55555555) << 1)
    value = ((value >> 2) & 0x33333333) | ((value & 0x33333333) << 2)
    value = ((value >> 4) & 0x0F0F0F0F) | ((value & 0x0F0F0F0F) << 4)
    return (((value & 0xFF000000) >> 24) | ((value & 0x00FF0000) >> 8)
            | ((value & 0x0000FF00) << 8) | ((value & 0x000000FF) << 24))


def _reverse64(value: int) -> int:
    mask1 = 0x5555555555555555
    mask2 = 0x3333333333333333
    mask4 = 0x0F0F0F0F0F0F0F0F
    value = ((value >> 1) & mask1) | ((value & mask1) << 1)
    value = ((value >> 2) & mask2) | ((value & mask2) << 2)
    value = ((value >> 4) & mask4) | ((value & mask4) << 4)
    return (((value & 0xFF00000000000000) >> 56)
            | ((value & 0x00FF000000000000) >> 40)
            | ((value & 0x0000FF0000000000) >> 24)
            | ((value & 0x000000FF00000000) >> 8)
            | ((value & 0x00000000FF000000) << 8)
            | ((value & 0x0000000000FF0000) << 24)
            | ((value & 0x000000000000FF00) << 40)
            | ((value & 0x00000000000000FF) << 56))


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None
                and (type(input_length) is not int or input_length < 0))):
        return INVALID_RESULT, b""
    if (input_is_null or values is None or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and input_length != len(values))
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""
    if (len(values) != MAX_VALID_INPUT_LENGTH
            or not 0 <= values[0] <= U32_MAX):
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < OUTPUT_BYTES):
        return OUTPUT_ERROR, b""

    reversed32 = _reverse32(values[0])
    reversed64 = _reverse64(values[1] & ((1 << 64) - 1))
    return OUTPUT_BYTES, struct.pack("<IQ", reversed32, reversed64)
