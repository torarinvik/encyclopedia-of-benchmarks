"""Independent bounded oracle for the Java finite-automaton matcher."""

from __future__ import annotations

import struct
from typing import Sequence

MAX_TEXT_LENGTH = 256
MAX_PATTERN_LENGTH = 32
MAX_INPUT_LENGTH = 2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 4 * MAX_TEXT_LENGTH


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return (result, output bytes) using direct slices rather than a DFA."""
    if (
        not isinstance(values, (tuple, list))
        or len(values) < 2
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)
    ):
        return -1, b""

    text_length, pattern_length = values[:2]
    if not 0 <= text_length <= MAX_TEXT_LENGTH or not 1 <= pattern_length <= MAX_PATTERN_LENGTH:
        return -1, b""
    if len(values) != 2 + text_length + pattern_length:
        return -1, b""

    text = values[2 : 2 + text_length]
    pattern = values[2 + text_length :]
    if any(not 0 <= symbol <= 127 for symbol in (*text, *pattern)):
        return -1, b""

    if type(output_is_null) is not bool:
        return -1, b""
    if type(output_capacity) is not int or output_capacity < 0:
        return -1, b""
    if output_is_null:
        return -2, b""

    matches = [
        start
        for start in range(max(0, text_length - pattern_length + 1))
        if text[start : start + pattern_length] == pattern
    ]
    output = b"".join(struct.pack("<i", start) for start in matches)
    if output_capacity < len(output):
        return -2, b""
    return len(output), output
