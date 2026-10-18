"""Independent oracle for the pinned Lua unsigned-integer base conversion."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MIN_BASE = 2
MAX_BASE = 1 << 26
MAX_DIGITS = 64
MAX_INPUT_LENGTH = 3 + MAX_DIGITS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_DIGITS = MAX_DIGITS * 26
MAX_OUTPUT_BYTES = MAX_OUTPUT_DIGITS * 4
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
    """Convert canonical little-endian source-base digits to target-base digits."""
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
    if not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT, b""

    source_base, target_base, digit_count = values[:3]
    if not MIN_BASE <= source_base <= MAX_BASE or not MIN_BASE <= target_base <= MAX_BASE:
        return INVALID_RESULT, b""
    if not 0 <= digit_count <= MAX_DIGITS or len(values) != 3 + digit_count:
        return INVALID_RESULT, b""
    digits = values[3:]
    if any(not 0 <= digit < source_base for digit in digits):
        return INVALID_RESULT, b""
    if digit_count and digits[-1] == 0:
        return INVALID_RESULT, b""

    number = 0
    for digit in reversed(digits):
        number = number * source_base + digit
    converted: list[int] = []
    while number:
        number, digit = divmod(number, target_base)
        converted.append(digit)
    output = b"".join(struct.pack("<I", digit) for digit in converted)
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
