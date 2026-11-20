"""Raita probe-order reference for bounded byte-string search."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TEXT_LENGTH = 255
MAX_PATTERN_LENGTH = 64
MAX_ALPHABET = 128
MAX_VALID_INPUT_LENGTH = 2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = 322
MAX_OUTPUT_BYTES = MAX_TEXT_LENGTH * 8
WORKSPACE_BYTES = 4096
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[bytes, bytes] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values):
        return None
    text_length, pattern_length = values[:2]
    if not 0 <= text_length <= MAX_TEXT_LENGTH:
        return None
    if not 1 <= pattern_length <= MAX_PATTERN_LENGTH:
        return None
    if len(values) != 2 + text_length + pattern_length:
        return None
    payload = values[2:]
    if any(not 0 <= byte < MAX_ALPHABET for byte in payload):
        return None
    return (bytes(payload[:text_length]), bytes(payload[text_length:]))


def _raita_search(text: bytes, pattern: bytes) -> list[int]:
    n, m = len(text), len(pattern)
    if m > n:
        return []
    shifts = [m] * MAX_ALPHABET
    for index in range(m - 1):
        shifts[pattern[index]] = m - index - 1
    middle = m // 2
    positions: list[int] = []
    alignment = 0
    while alignment <= n - m:
        last_byte = text[alignment + m - 1]
        if (pattern[m - 1] == last_byte
                and pattern[0] == text[alignment]
                and pattern[middle] == text[alignment + middle]):
            interior_matches = True
            for index in range(1, m - 1):
                if pattern[index] != text[alignment + index]:
                    interior_matches = False
                    break
            if interior_matches:
                positions.append(alignment)
        alignment += shifts[last_byte]
    return positions


def _encode_positions(positions: Sequence[int]) -> bytes:
    return b"".join(position.to_bytes(8, "little", signed=True)
                    for position in positions)


def expected_output(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None, output_is_null: bool = False,
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    text, pattern = parsed
    encoded = _encode_positions(_raita_search(text, pattern))
    if (type(output_is_null) is not bool or output_is_null
            or (output_capacity is not None
                and (type(output_capacity) is not int
                     or output_capacity < len(encoded)))):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
