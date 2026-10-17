"""Independent bounded oracle for ASCII suffix-array order."""

from __future__ import annotations

import struct
from typing import Sequence

MAX_TEXT_LENGTH = 64
MAX_INPUT_LENGTH = 1 + MAX_TEXT_LENGTH
MAX_OUTPUT_BYTES = 8 * MAX_TEXT_LENGTH
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return output byte length and little-endian suffix starts."""
    if (
        not isinstance(values, (tuple, list))
        or len(values) < 1
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)
    ):
        return INVALID_RESULT, b""

    count = values[0]
    if not 0 <= count <= MAX_TEXT_LENGTH or len(values) != 1 + count:
        return INVALID_RESULT, b""
    text = values[1:]
    if any(not 0 <= code <= 127 for code in text):
        return INVALID_RESULT, b""
    if type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if type(output_capacity) is not int or output_capacity < 0:
        return INVALID_RESULT, b""
    if output_is_null:
        return OUTPUT_ERROR, b""

    suffix_starts = sorted(range(count), key=lambda start: tuple(text[start:]))
    output = b"".join(struct.pack("<q", start) for start in suffix_starts)
    if output_capacity < len(output):
        return OUTPUT_ERROR, b""
    return len(output), output
