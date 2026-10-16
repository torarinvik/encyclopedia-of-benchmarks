"""Oracle for the bounded Ruby products-of-all-other-elements contract."""

from __future__ import annotations

import struct

MAX_ARRAY_LENGTH = 32
MAX_INPUT_LENGTH = MAX_ARRAY_LENGTH + 2  # admit one extra packed value
MAX_ABS_VALUE = 2
MAX_OUTPUT_BYTES = MAX_ARRAY_LENGTH * 8
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return output byte count and little-endian signed-64 result vector."""
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT, b""

    length = values[0]
    if not 0 <= length <= MAX_ARRAY_LENGTH or len(values) != length + 1:
        return INVALID_RESULT, b""
    elements = values[1:]
    if any(value < -MAX_ABS_VALUE or value > MAX_ABS_VALUE for value in elements):
        return INVALID_RESULT, b""
    if length < 2:
        return 0, b""

    # Preserve the final Ruby products(nums) implementation's prefix and
    # right-to-left suffix update order.
    result = [1]
    for index in range(length - 1):
        result.append(elements[index] * result[index])
    suffix = 1
    for index in range(length - 1, 0, -1):
        value = elements[index]
        result[index - 1] *= suffix * value
        suffix *= value
    return length * 8, struct.pack("<" + "q" * length, *result)
