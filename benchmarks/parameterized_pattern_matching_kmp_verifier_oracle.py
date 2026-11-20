"""Independent bijection-per-window oracle for parameterized matching."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TEXT = 64
MAX_PATTERN = 16
MAX_ALPHABET = 16
MAX_VALID_INPUT_LENGTH = 3 + MAX_TEXT + MAX_PATTERN
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (MAX_TEXT + 1)
WORKSPACE_BYTES = 4096


def _window_matches(pattern: Sequence[int], window: Sequence[int],
                    alphabet_size: int) -> bool:
    pattern_to_text = [-1] * alphabet_size
    text_to_pattern = [-1] * alphabet_size
    for pattern_symbol, text_symbol in zip(pattern, window):
        old_text = pattern_to_text[pattern_symbol]
        old_pattern = text_to_pattern[text_symbol]
        if old_text != -1 and old_text != text_symbol:
            return False
        if old_pattern != -1 and old_pattern != pattern_symbol:
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
                                             or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if (len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    text_length, pattern_length, alphabet_size = values[:3]
    if (not 0 <= text_length <= MAX_TEXT
            or not 1 <= pattern_length <= MAX_PATTERN
            or not 1 <= alphabet_size <= MAX_ALPHABET
            or len(values) != 3 + text_length + pattern_length):
        return -1, b""
    text = values[3:3 + text_length]
    pattern = values[3 + text_length:]
    if any(not 0 <= symbol < alphabet_size for symbol in (*text, *pattern)):
        return -1, b""

    matches = []
    for start in range(max(0, text_length - pattern_length + 1)):
        if _window_matches(pattern, text[start:start + pattern_length], alphabet_size):
            matches.append(start)
    payload = b"".join(struct.pack("<q", value)
                       for value in (len(matches), *matches))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
