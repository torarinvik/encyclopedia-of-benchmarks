"""Dictionary-scan reference for bounded left-to-right MaxMatch."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TEXT_LENGTH = 64
MAX_WORDS = 16
MAX_WORD_LENGTH = 8
MAX_VALID_INPUT_LENGTH = 210
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_TEXT_LENGTH + 1
WORKSPACE_BYTES = 320
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int]) -> tuple[tuple[int, ...], list[tuple[int, ...]]] | None:
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    text_length, word_count = values[:2]
    if not 0 <= text_length <= MAX_TEXT_LENGTH or not 0 <= word_count <= MAX_WORDS:
        return None
    cursor = 2
    if cursor + text_length > len(values):
        return None
    text = tuple(values[cursor:cursor + text_length])
    if any(not 97 <= character <= 122 for character in text):
        return None
    cursor += text_length
    words: list[tuple[int, ...]] = []
    for _ in range(word_count):
        if cursor >= len(values):
            return None
        word_length = values[cursor]
        cursor += 1
        if not 1 <= word_length <= MAX_WORD_LENGTH or cursor + word_length > len(values):
            return None
        word = tuple(values[cursor:cursor + word_length])
        if any(not 97 <= character <= 122 for character in word):
            return None
        words.append(word)
        cursor += word_length
    if cursor != len(values):
        return None
    return text, words


def expected_output(
    values: Sequence[int],
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return `(status, count-prefixed token-ID bytes)` for a packed input."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None
            and (type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)):
        return INVALID_RESULT, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    parsed = _parse(values)
    if parsed is None:
        return INVALID_RESULT, b""
    text, words = parsed

    token_ids: list[int] = []
    position = 0
    while position < len(text):
        best_length = 0
        best_id = 0
        for word_index, word in enumerate(words):
            word_length = len(word)
            if word_length <= best_length or position + word_length > len(text):
                continue
            if text[position:position + word_length] == word:
                best_length = word_length
                best_id = word_index + 1
        token_ids.append(best_id)
        position += best_length if best_length else 1

    output = bytes((len(token_ids), *token_ids))
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return INSUFFICIENT_CAPACITY, b""
    return len(output), output
