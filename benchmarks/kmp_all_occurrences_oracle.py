"""Independent bounded oracle for JavaScript KMP all-occurrences search."""

from __future__ import annotations

import struct
from typing import Sequence

MAX_TEXT_LENGTH = 256
MAX_PATTERN_LENGTH = 64
MAX_INPUT_LENGTH = 2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH
MAX_OUTPUT_BYTES = 8 * MAX_TEXT_LENGTH
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return output byte length and LE i64 match offsets, or an ABI error."""
    if (
        not isinstance(values, (tuple, list))
        or len(values) < 2
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)
    ):
        return INVALID_RESULT, b""

    text_length, pattern_length = values[:2]
    if not 0 <= text_length <= MAX_TEXT_LENGTH:
        return INVALID_RESULT, b""
    if not 1 <= pattern_length <= MAX_PATTERN_LENGTH:
        return INVALID_RESULT, b""
    if len(values) != 2 + text_length + pattern_length:
        return INVALID_RESULT, b""
    text = values[2 : 2 + text_length]
    pattern = values[2 + text_length :]
    if any(not 0 <= code <= 127 for code in (*text, *pattern)):
        return INVALID_RESULT, b""
    if type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if type(output_capacity) is not int or output_capacity < 0:
        return INVALID_RESULT, b""
    if output_is_null:
        return OUTPUT_ERROR, b""

    last_start = len(text) - pattern_length
    starts = [
        start
        for start in range(max(0, last_start + 1))
        if text[start : start + pattern_length] == pattern
    ]

    output = b"".join(struct.pack("<q", start) for start in starts)
    if output_capacity < len(output):
        return OUTPUT_ERROR, b""
    return len(output), output
