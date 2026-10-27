"""Bounded oracle for the one-lookahead LZ78 parser in Chapter 108."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TEXT = 32
MIN_CHARACTER = 32
MAX_CHARACTER = 126
MAX_PARSEABLE_INPUT_LENGTH = 34
MAX_VALID_INPUT_LENGTH = 33
MAX_OUTPUT_BYTES = 16 * MAX_TEXT
MAX_WORKSPACE_BYTES = 4096
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n = values[0]
    if not 0 <= n <= MAX_TEXT or len(values) != n + 1:
        return None
    text = values[1:]
    if any(not MIN_CHARACTER <= value <= MAX_CHARACTER for value in text):
        return None
    return bytes(text)


def _longest_dictionary_match(dictionary: list[bytes], text: bytes, start: int) -> int:
    if start >= len(text):
        return 0
    return max((len(phrase) for phrase in dictionary
                if phrase and text.startswith(phrase, start)), default=0)


def _flexible_tokens(text: bytes) -> list[tuple[int, int]] | None:
    dictionary: list[bytes] = [b""]
    phrase_ids: dict[bytes, int] = {b"": 0}
    tokens: list[tuple[int, int]] = []
    position = 0
    while position < len(text):
        # Match the bounded framing used by the local LZ78 profile: if the
        # remaining suffix is already one dictionary phrase, emit its index
        # with the reserved zero end marker.
        remaining = text[position:]
        final_index = phrase_ids.get(remaining)
        if final_index is not None and final_index != 0:
            tokens.append((final_index, 0))
            position = len(text)
            break

        best_key: tuple[int, int, int] | None = None
        best_choice: tuple[int, int, bytes] | None = None
        for parent_index, prefix in enumerate(dictionary):
            prefix_length = len(prefix)
            next_character_position = position + prefix_length
            if next_character_position >= len(text):
                continue
            if not text.startswith(prefix, position):
                continue
            character = text[next_character_position]
            phrase = prefix + bytes((character,))
            next_position = position + len(phrase)
            trial_dictionary = dictionary
            if phrase not in phrase_ids:
                trial_dictionary = dictionary + [phrase]
            next_match = _longest_dictionary_match(trial_dictionary, text, next_position)
            # The advancement endpoint is measured from the current position:
            # current phrase length plus the following greedy dictionary match.
            # Ties are refined by longer current phrase, then smaller parent id.
            key = (len(phrase) + next_match, len(phrase), -parent_index)
            if best_key is None or key > best_key:
                best_key = key
                best_choice = (parent_index, character, phrase)

        if best_choice is None:
            return None
        parent_index, character, phrase = best_choice
        tokens.append((parent_index, character))
        if phrase not in phrase_ids:
            phrase_ids[phrase] = len(dictionary)
            dictionary.append(phrase)
        position += len(phrase)
    return tokens


def evaluate(values: Sequence[int] | None) -> tuple[int, bytes]:
    text = _parse(values)
    if text is None:
        return INVALID_RESULT, b""
    tokens = _flexible_tokens(text)
    if tokens is None:
        return INVALID_RESULT, b""
    raw = b"".join(struct.pack("<qq", parent, character) for parent, character in tokens)
    return len(raw), raw


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    result, raw = evaluate(values)
    if result < 0:
        return result, raw
    if output_is_null or capacity is not None and capacity < len(raw):
        return OUTPUT_ERROR, b""
    return result, raw
