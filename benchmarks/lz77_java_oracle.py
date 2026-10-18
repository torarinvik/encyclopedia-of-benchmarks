"""Oracle for the pinned Java LZ77 compressor on printable ASCII."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MIN_INPUT_LENGTH = 0
MAX_INPUT_LENGTH = 64
MIN_CHARACTER = 32
MAX_CHARACTER = 126
WINDOW_SIZE = 4096
LOOKAHEAD_SIZE = 16
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
    return characters


def _compress(characters: Sequence[int]) -> list[tuple[int, int, int]]:
    tokens: list[tuple[int, int, int]] = []
    current = 0
    text_length = len(characters)
    while current < text_length:
        best_distance = 0
        best_length = 0
        search_start = max(0, current - WINDOW_SIZE)
        lookahead_end = min(current + LOOKAHEAD_SIZE, text_length)
        for candidate in range(search_start, current):
            match_length = 0
            while current + match_length < lookahead_end:
                source = candidate + match_length
                if source >= current:
                    distance = current - candidate
                    source = candidate + (match_length % distance)
                if characters[source] != characters[current + match_length]:
                    break
                match_length += 1
            if match_length > best_length:
                best_distance = current - candidate
                best_length = match_length

        if current + best_length < text_length:
            next_character = characters[current + best_length]
        else:
            next_character = 0
        tokens.append((best_distance, best_length, next_character))
        current += best_length if next_character == 0 else best_length + 1
    return tokens


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return little-endian (offset, length, next-character) records or ABI error."""
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
