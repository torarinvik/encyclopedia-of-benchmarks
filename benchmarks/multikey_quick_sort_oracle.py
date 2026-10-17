"""Oracle for the bounded pinned C multikey quicksort (ssort2) implementation."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MIN_STRING_COUNT = 0
MAX_STRING_COUNT = 32
MIN_STRING_LENGTH = 0
MAX_STRING_LENGTH = 16
MIN_BYTE = 1
MAX_BYTE = 127
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
MAX_INPUT_WORDS = 1 + MAX_STRING_COUNT * (1 + MAX_STRING_LENGTH)
MAX_PARSEABLE_INPUT_WORDS = MAX_INPUT_WORDS + 1
MAX_OUTPUT_BYTES = 4 * MAX_INPUT_WORDS
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Sort length-prefixed ASCII byte strings and encode them as LE i32 words."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_WORDS:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I32_MIN <= value <= I32_MAX for value in values):
        return INVALID_RESULT, b""

    string_count = values[0]
    if not MIN_STRING_COUNT <= string_count <= MAX_STRING_COUNT:
        return INVALID_RESULT, b""

    strings: list[bytes] = []
    position = 1
    for _ in range(string_count):
        if position >= len(values):
            return INVALID_RESULT, b""
        string_length = values[position]
        position += 1
        if not MIN_STRING_LENGTH <= string_length <= MAX_STRING_LENGTH:
            return INVALID_RESULT, b""
        end = position + string_length
        if end > len(values):
            return INVALID_RESULT, b""
        string_bytes = values[position:end]
        if any(not MIN_BYTE <= byte <= MAX_BYTE for byte in string_bytes):
            return INVALID_RESULT, b""
        strings.append(bytes(string_bytes))
        position = end

    if position != len(values):
        return INVALID_RESULT, b""

    ordered_strings = sorted(strings)
    output_words = [len(ordered_strings)]
    for string_bytes in ordered_strings:
        output_words.extend((len(string_bytes), *string_bytes))
    encoded = struct.pack("<" + "i" * len(output_words), *output_words)
    if len(encoded) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(encoded)
    ):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
