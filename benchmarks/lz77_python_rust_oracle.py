"""Oracle for the common ASCII domain of pinned Python and Rust LZ77."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MIN_INPUT_LENGTH = 0
MAX_INPUT_LENGTH = 64
MIN_CHARACTER = 32
MAX_CHARACTER = 126
WINDOW_SIZE = 13
LOOKAHEAD_SIZE = 6
SEARCH_BUFFER_SIZE = WINDOW_SIZE - LOOKAHEAD_SIZE
MAX_VALID_INPUT_LENGTH = 1 + MAX_INPUT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 24 * MAX_INPUT_LENGTH
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _parse(values: Sequence[int] | None) -> list[int] | None:
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
               for value in values)
    ):
        return None
    length = values[0]
    if not MIN_INPUT_LENGTH <= length <= MAX_INPUT_LENGTH or len(values) != 1 + length:
        return None
    characters = list(values[1:])
    if any(not MIN_CHARACTER <= value <= MAX_CHARACTER for value in characters):
        return None
    if characters and characters.count(characters[-1]) != 1:
        return None
    return characters


def _match_length(
    text: Sequence[int], window: Sequence[int], text_index: int, window_index: int
) -> int:
    if text[text_index] != window[window_index]:
        return 0
    extended_window = [*window, text[text_index]]
    return 1 + _match_length(text, extended_window, text_index + 1, window_index + 1)


def _compress(characters: Sequence[int]) -> list[tuple[int, int, int]]:
    tokens: list[tuple[int, int, int]] = []
    search_buffer: list[int] = []
    text = list(characters)
    while text:
        length = 0
        offset = 0
        if search_buffer:
            for index, character in enumerate(search_buffer):
                if character == text[0]:
                    found_offset = len(search_buffer) - index
                    found_length = _match_length(text, search_buffer, 0, index)
                    found_length = min(found_length, len(text) - 1)
                    if found_length >= length:
                        offset, length = found_offset, found_length

        indicator = text[length]
        tokens.append((offset, length, indicator))
        search_buffer.extend(text[:length + 1])
        if len(search_buffer) > SEARCH_BUFFER_SIZE:
            search_buffer = search_buffer[-SEARCH_BUFFER_SIZE:]
        text = text[length + 1:]
    return tokens


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return little-endian (offset, length, indicator) records or ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT, b""

    characters = _parse(values)
    if characters is None:
        return INVALID_RESULT, b""
    tokens = _compress(characters)
    output = b"".join(struct.pack("<qqq", *token) for token in tokens)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
