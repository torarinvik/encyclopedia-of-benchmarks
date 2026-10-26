"""Independent symbol-bijection verifier for parameterized matches."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TEXT = 24
MAX_PATTERN = 8
MAX_INPUT = 2 + MAX_TEXT + MAX_PATTERN
ALPHABET = 16


def _matches(pattern: Sequence[int], window: Sequence[int]) -> bool:
    pattern_to_text = [-1] * ALPHABET
    text_to_pattern = [-1] * ALPHABET
    for pattern_symbol, text_symbol in zip(pattern, window):
        mapped_text = pattern_to_text[pattern_symbol]
        mapped_pattern = text_to_pattern[text_symbol]
        if (mapped_text >= 0 and mapped_text != text_symbol
                or mapped_pattern >= 0 and mapped_pattern != pattern_symbol):
            return False
        pattern_to_text[pattern_symbol] = text_symbol
        text_to_pattern[text_symbol] = pattern_symbol
    return True


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if (len(values) < 3 or len(values) > MAX_INPUT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    text_length, pattern_length = values[:2]
    if (not 0 <= text_length <= MAX_TEXT or not 1 <= pattern_length <= MAX_PATTERN
            or len(values) != 2 + text_length + pattern_length):
        return -1, b""
    text = values[2:2 + text_length]
    pattern = values[2 + text_length:]
    if any(not 0 <= value < ALPHABET for value in (*text, *pattern)):
        return -1, b""

    matches = [start for start in range(text_length - pattern_length + 1)
               if _matches(pattern, text[start:start + pattern_length])]
    payload = b"".join(struct.pack("<q", value)
                       for value in (len(matches), *matches))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
