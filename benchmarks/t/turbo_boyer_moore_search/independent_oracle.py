"""Direct-window reference for all exact byte-pattern occurrences."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TEXT_LENGTH = 255
MAX_PATTERN_LENGTH = 64
MAX_PARSEABLE_INPUT_LENGTH = 322
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[list[int], list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, m = values[0], values[1]
    if not 0 <= n <= MAX_TEXT_LENGTH or not 1 <= m <= MAX_PATTERN_LENGTH:
        return None
    if len(values) != n + m + 2:
        return None
    text = list(values[2:2 + n])
    pattern = list(values[2 + n:])
    if any(byte < 0 or byte > 127 for byte in text + pattern):
        return None
    return text, pattern


def _encode_directly(positions: Sequence[int]) -> bytes:
    result = bytearray()
    for position in positions:
        for shift in range(0, 64, 8):
            result.append((position >> shift) & 0xFF)
    return bytes(result)


def expected_output(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None, output_is_null: bool = False,
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    text, pattern = parsed
    m = len(pattern)
    positions = [start for start in range(len(text) - m + 1)
                 if text[start:start + m] == pattern]
    encoded = _encode_directly(positions)
    if (type(output_is_null) is not bool or output_is_null
            or (output_capacity is not None
                and (type(output_capacity) is not int
                     or output_capacity < len(encoded))):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
