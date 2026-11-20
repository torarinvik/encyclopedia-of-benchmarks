"""Trie-based independent reference for the bounded MaxMatch contract."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TEXT_LENGTH = 64
MAX_WORDS = 16
MAX_WORD_LENGTH = 8
MAX_VALID_INPUT_LENGTH = 210
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_TEXT_LENGTH + 1
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _unpack(values: Sequence[int]) -> tuple[tuple[int, ...], list[tuple[int, ...]]] | None:
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(item) is not int or item < I64_MIN or item > I64_MAX for item in values):
        return None
    text_size = values[0]
    dictionary_size = values[1]
    if not 0 <= text_size <= MAX_TEXT_LENGTH or not 0 <= dictionary_size <= MAX_WORDS:
        return None
    text_end = 2 + text_size
    if text_end > len(values):
        return None
    text = tuple(values[2:text_end])
    if any(character < 97 or character > 122 for character in text):
        return None
    words: list[tuple[int, ...]] = []
    cursor = text_end
    for _ in range(dictionary_size):
        if cursor >= len(values):
            return None
        size = values[cursor]
        cursor += 1
        if not 1 <= size <= MAX_WORD_LENGTH or cursor + size > len(values):
            return None
        word = tuple(values[cursor:cursor + size])
        if any(character < 97 or character > 122 for character in word):
            return None
        words.append(word)
        cursor += size
    return (text, words) if cursor == len(values) else None


def expected_output(
    values: Sequence[int],
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(input_is_null) is not bool or type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if (input_length is not None
            and (type(input_length) is not int
                 or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)):
        return INVALID_RESULT, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    unpacked = _unpack(values)
    if unpacked is None:
        return INVALID_RESULT, b""
    text, words = unpacked

    children: list[dict[int, int]] = [{}]
    terminal_ids = [0]
    for word_id, word in enumerate(words, start=1):
        node = 0
        for character in word:
            child = children[node].get(character)
            if child is None:
                child = len(children)
                children[node][character] = child
                children.append({})
                terminal_ids.append(0)
            node = child
        if terminal_ids[node] == 0:
            terminal_ids[node] = word_id

    token_ids: list[int] = []
    position = 0
    while position < len(text):
        node = 0
        best_id = 0
        best_end = position
        end = position
        while end < len(text):
            child = children[node].get(text[end])
            if child is None:
                break
            node = child
            end += 1
            if terminal_ids[node] != 0:
                best_id = terminal_ids[node]
                best_end = end
        token_ids.append(best_id)
        position = best_end if best_id != 0 else position + 1

    output = bytes((len(token_ids), *token_ids))
    if output_is_null or (capacity is not None and capacity < len(output)):
        return INSUFFICIENT_CAPACITY, b""
    return len(output), output
