"""Direct bounded oracle for DOI 634's rightmost infinite-window LZ77 parse."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TEXT_LENGTH = 64
MIN_CHARACTER = 32
MAX_CHARACTER = 126
MAX_VALID_INPUT_LENGTH = 1 + MAX_TEXT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 24 * MAX_TEXT_LENGTH
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return None
    n = values[0]
    if type(n) is not int or not 0 <= n <= MAX_TEXT_LENGTH or len(values) != n + 1:
        return None
    text = tuple(values[1:])
    if any(not MIN_CHARACTER <= c <= MAX_CHARACTER for c in text):
        return None
    return text


def _tokens(text: tuple[int, ...]) -> list[tuple[int, int, int]]:
    tokens = []
    q = 0
    n = len(text)
    while q < n:
        best_len = 0
        best_pos = -1
        for p in range(q):
            length = 0
            while q + length < n and text[p + length] == text[q + length]:
                length += 1
            if length > best_len or length == best_len and length > 0 and p > best_pos:
                best_len, best_pos = length, p
        source_pos = best_pos if best_len else 0
        next_pos = q + best_len
        next_char = text[next_pos] if next_pos < n else 0
        tokens.append((source_pos, best_len, next_char))
        q = next_pos + 1 if next_char else next_pos
    return tokens


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and isinstance(values, (list, tuple)) and input_length != len(values)):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    text = _parse(values)
    if text is None:
        return INVALID_RESULT, b""
    payload = b"".join(struct.pack("<qqq", *token) for token in _tokens(text))
    if output_is_null or capacity is not None and capacity < len(payload):
        return OUTPUT_ERROR, b""
    return len(payload), payload
