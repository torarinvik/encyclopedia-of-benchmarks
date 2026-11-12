"""Direct byte-by-byte occurrence oracle for the Two-Way profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

try:
    from .primary_oracle import MAX_INPUT_LENGTH, MAX_PATTERN_LENGTH, MAX_TEXT_LENGTH
except ImportError:  # Direct import from the package directory.
    from primary_oracle import MAX_INPUT_LENGTH, MAX_PATTERN_LENGTH, MAX_TEXT_LENGTH


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (
        type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or capacity is not None and (type(capacity) is not int or capacity < 0)
        or input_length is not None
        and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
        or input_is_null and values not in (None, [], ())
        or not input_is_null
        and values is not None
        and input_length is not None
        and input_length != len(values)
    ):
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1, b""
    text_length, pattern_length = values[:2]
    if not 0 <= text_length <= MAX_TEXT_LENGTH or not 0 <= pattern_length <= MAX_PATTERN_LENGTH:
        return -1, b""
    if len(values) != 2 + text_length + pattern_length:
        return -1, b""
    text = values[2:2 + text_length]
    pattern = values[2 + text_length:]
    if any(not 0 <= value <= 255 for value in (*text, *pattern)):
        return -1, b""
    if pattern_length == 0:
        matches = list(range(text_length + 1))
    else:
        matches = [
            start for start in range(text_length - pattern_length + 1)
            if all(text[start + offset] == pattern[offset] for offset in range(pattern_length))
        ]
    payload = struct.pack("<" + "q" * len(matches), *matches)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
