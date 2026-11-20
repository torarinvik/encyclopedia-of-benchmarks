"""Turbo Boyer–Moore state-machine reference for byte-string search."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TEXT_LENGTH = 255
MAX_PATTERN_LENGTH = 64
MAX_ALPHABET = 128
MAX_PARSEABLE_INPUT_LENGTH = 322
MAX_VALID_INPUT_LENGTH = 2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH
MAX_OUTPUT_BYTES = MAX_TEXT_LENGTH * 8
WORKSPACE_BYTES = 5100
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
    text = bytes(payload[:text_length])
    pattern = bytes(payload[text_length:])
    return text, pattern


def _good_suffix(pattern: bytes) -> list[int]:
    length = len(pattern)
    suffix = [0] * length
    suffix[length - 1] = length
    g = length - 1
    f = 0
    for index in range(length - 2, -1, -1):
        if index > g and suffix[index + length - 1 - f] < index - g:
            suffix[index] = suffix[index + length - 1 - f]
        else:
            if index < g:
                g = index
            f = index
            while g >= 0 and pattern[g] == pattern[g + length - 1 - f]:
                g -= 1
            suffix[index] = f - g

    shifts = [length] * length
    border = 0
    for index in range(length - 1, -1, -1):
        if suffix[index] == index + 1:
            while border < length - 1 - index:
                if shifts[border] == length:
                    shifts[border] = length - 1 - index
                border += 1
    for index in range(length - 1):
        shifts[length - 1 - suffix[index]] = length - 1 - index
    return shifts


def _turbo_search(text: bytes, pattern: bytes) -> list[int]:
    text_length = len(text)
    pattern_length = len(pattern)
    if pattern_length > text_length:
        return []

    bad_character = [pattern_length] * MAX_ALPHABET
    for index in range(pattern_length - 1):
        bad_character[pattern[index]] = pattern_length - index - 1
    good_suffix = _good_suffix(pattern)

    positions: list[int] = []
    alignment = 0
    remembered = 0
    shift = pattern_length
    while alignment <= text_length - pattern_length:
        index = pattern_length - 1
        while index >= 0 and pattern[index] == text[alignment + index]:
            index -= 1
            if remembered != 0 and index == pattern_length - 1 - shift:
                index -= remembered
        if index < 0:
            positions.append(alignment)
            shift = good_suffix[0]
            remembered = pattern_length - shift
        else:
            matched_suffix = pattern_length - 1 - index
            turbo_shift = remembered - matched_suffix
            bad_shift = (bad_character[text[alignment + index]]
                         - pattern_length + 1 + index)
            shift = max(turbo_shift, bad_shift, good_suffix[index])
            if shift == good_suffix[index]:
                remembered = min(pattern_length - shift, matched_suffix)
            else:
                if turbo_shift < bad_shift:
                    shift = max(shift, remembered + 1)
                remembered = 0
        alignment += shift
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
    encoded = _encode_positions(_turbo_search(text, pattern))
    if (type(output_is_null) is not bool or output_is_null
            or (output_capacity is not None
                and (type(output_capacity) is not int
                     or output_capacity < len(encoded)))):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
