"""Independent bounded oracle for Java PriorityQueue sorting semantics."""

from __future__ import annotations

import struct
from typing import Sequence

MAX_COUNT = 128
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_I32 = -(1 << 31)
MAX_I32 = (1 << 31) - 1
MAX_VALID_INPUT_LENGTH = 1 + MAX_COUNT
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 4 * MAX_COUNT


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return (byte count/error, sorted signed-i32 output) for one call."""
    if type(input_is_null) is not bool or type(output_is_null) is not bool:
        return -1, b""
    if input_is_null:
        return -1, b""
    if (
        not isinstance(values, (tuple, list))
        or len(values) < 1
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return -1, b""

    count = values[0]
    if not 0 <= count <= MAX_COUNT or len(values) != 1 + count:
        return -1, b""
    items = values[1:]
    if any(not MIN_I32 <= value <= MAX_I32 for value in items):
        return -1, b""
    if type(output_capacity) is not int or output_capacity < 0:
        return -1, b""
    if output_is_null:
        return -2, b""

    output = b"".join(struct.pack("<i", value) for value in sorted(items))
    if output_capacity < len(output):
        return -2, b""
    return len(output), output
