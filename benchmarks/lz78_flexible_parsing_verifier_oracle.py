"""Independent byte-string verifier for the bounded flexible LZ78 profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TEXT = 32
MIN_CHARACTER = 32
MAX_CHARACTER = 126
MAX_INPUT_LENGTH = 34
MAX_OUTPUT_BYTES = 16 * MAX_TEXT
MAX_WORKSPACE_BYTES = 4096


def _independent_parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n = values[0]
    if type(n) is not int or not 0 <= n <= MAX_TEXT or len(values) != n + 1:
        return None
    if any(not MIN_CHARACTER <= value <= MAX_CHARACTER for value in values[1:]):
        return None
    return bytes(values[1:])


def _match_length(phrases: list[bytes], text: bytes, offset: int) -> int:
    longest = 0
    for phrase in phrases[1:]:
        limit = min(len(phrase), len(text) - offset)
        if limit > longest and text[offset:offset + limit] == phrase[:limit] and limit == len(phrase):
            longest = limit
    return longest


def _replay(text: bytes) -> list[tuple[int, int]] | None:
    phrases = [b""]
    index_of = {b"": 0}
    encoded: list[tuple[int, int]] = []
    offset = 0
    while offset < len(text):
        suffix_id = index_of.get(text[offset:])
        if suffix_id is not None and suffix_id > 0:
            encoded.append((suffix_id, 0))
            offset = len(text)
            continue

        winning = None
        winning_rank = None
        # Enumerate possible phrases by end position. Prefix-closure means
        # each possible codeword has the form existing-prefix + next byte.
        for end in range(offset + 1, len(text) + 1):
            phrase = text[offset:end]
            prefix_id = index_of.get(phrase[:-1])
            if prefix_id is None:
                continue
            following = end
            after = len(text) - following
            best_next = 0
            if after:
                next_phrases = phrases if phrase in index_of else phrases + [phrase]
                best_next = _match_length(next_phrases, text, following)
            rank = (len(phrase) + best_next, len(phrase), -prefix_id)
            if winning_rank is None or rank > winning_rank:
                winning_rank = rank
                winning = (prefix_id, phrase[-1], phrase)
        if winning is None:
            return None
        parent, last, phrase = winning
        encoded.append((parent, last))
        if phrase not in index_of:
            index_of[phrase] = len(phrases)
            phrases.append(phrase)
        offset += len(phrase)
    return encoded


def verify(values: Sequence[int] | None) -> tuple[int, bytes]:
    text = _independent_parse(values)
    if text is None:
        return -1, b""
    tokens = _replay(text)
    if tokens is None:
        return -1, b""
    # Check that each pair is a valid dictionary transition and that the
    # emitted phrases concatenate to precisely the input.
    dictionary = [b""]
    reconstructed = bytearray()
    for i, (parent, symbol) in enumerate(tokens):
        if not 0 <= parent < len(dictionary) or not MIN_CHARACTER <= symbol <= MAX_CHARACTER:
            if symbol == 0 and i == len(tokens) - 1 and 0 < parent < len(dictionary):
                reconstructed.extend(dictionary[parent])
                continue
            return -1, b""
        phrase = dictionary[parent] + bytes((symbol,))
        reconstructed.extend(phrase)
        if phrase not in dictionary:
            dictionary.append(phrase)
    if bytes(reconstructed) != text:
        return -1, b""
    raw = b"".join(struct.pack("<qq", parent, symbol) for parent, symbol in tokens)
    return len(raw), raw
