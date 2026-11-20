"""Independent bounded LZW decoding and direct pattern scan reference."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_ALPHABET = 16
MAX_PATTERN = 32
MAX_CODES = 32
MAX_EXPANDED_LENGTH = MAX_CODES * (MAX_CODES + 1) // 2
MAX_INPUT_LENGTH = 3 + MAX_PATTERN + MAX_CODES


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    alphabet_size, pattern_length, code_count = values[:3]
    if (not 1 <= alphabet_size <= MAX_ALPHABET or not 1 <= pattern_length <= MAX_PATTERN
            or not 0 <= code_count <= MAX_CODES
            or len(values) != 3 + pattern_length + code_count):
        return None
    pattern = tuple(values[3:3 + pattern_length])
    if any(not 0 <= symbol < alphabet_size for symbol in pattern):
        return None
    codes = values[3 + pattern_length:]
    if not codes:
        return pattern, ()
    if any(not isinstance(code, int) for code in codes) or not 0 <= codes[0] < alphabet_size:
        return None

    dictionary = [(symbol,) for symbol in range(alphabet_size)]
    previous = dictionary[codes[0]]
    text = list(previous)
    if len(codes) > 1:
        for code in codes[1:]:
            next_code = len(dictionary)
            if code < 0 or code > next_code:
                return None
            if code == next_code:
                phrase = previous + previous[:1]
            else:
                phrase = dictionary[code]
            new_phrase = previous + phrase[:1]
            dictionary.append(new_phrase)
            text.extend(phrase)
            if len(text) > MAX_EXPANDED_LENGTH:
                return None
            previous = phrase
    return pattern, tuple(text)


def _direct_scan(pattern: tuple[int, ...], text: tuple[int, ...]) -> list[int]:
    width = len(pattern)
    starts = [start for start in range(max(0, len(text) - width + 1))
              if text[start:start + width] == pattern]
    return [len(starts), *starts]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and (not isinstance(values, (list, tuple)) or input_length != len(values))):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    pattern, text = decoded
    words = _direct_scan(pattern, text)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
