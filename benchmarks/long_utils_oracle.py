"""Oracle for the four bounded 64-bit rotate operations in LongUtils."""
from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_INPUT_LENGTH = 4  # valid three-word input plus one parseable trailing-word case
VALID_INPUT_LENGTH = 3
INVALID_RESULT = -1
INSUFFICIENT_OUTPUT_CAPACITY = -2
MASK64 = (1 << 64) - 1


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT, b""
    if len(values) != VALID_INPUT_LENGTH or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return INVALID_RESULT, b""
    operation, value, distance = values
    if operation not in range(4) or not 0 <= distance <= 63:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < 8):
        return INSUFFICIENT_OUTPUT_CAPACITY, b""
    bits = value & MASK64
    if distance == 0:
        rotated = bits
    elif operation in (0, 1):
        rotated = ((bits << distance) | (bits >> (64 - distance))) & MASK64
    else:
        rotated = ((bits >> distance) | (bits << (64 - distance))) & MASK64
    return 8, struct.pack("<Q", rotated)
