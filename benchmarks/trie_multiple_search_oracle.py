"""Independent logical oracle for the pinned C++ multi-search trie."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_OPERATIONS = 64
MAX_WORD_LENGTH = 32
MAX_UNIQUE_WORDS = 32
MAX_VALID_INPUT_LENGTH = 1 + MAX_OPERATIONS * (2 + MAX_WORD_LENGTH)
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
FNV_OFFSET_BASIS = 14695981039346656037
FNV_PRIME = 1099511628211
MASK63 = (1 << 63) - 1


def _hash_trace(
    operation_count: int,
    observations: list[tuple[int, int | list[str] | None]],
    frequencies: dict[str, int],
) -> int:
    payload = bytearray(struct.pack("<H", operation_count))
    for opcode, result in observations:
        payload.extend(struct.pack("<B", opcode))
        if opcode == 1:
            assert isinstance(result, int)
            payload.extend(struct.pack("<B", result))
        elif opcode in (2, 3):
            assert isinstance(result, list)
            payload.extend(struct.pack("<H", len(result)))
            for word in result:
                encoded = word.encode("ascii")
                payload.extend(struct.pack("<B", len(encoded)))
                payload.extend(encoded)
    payload.extend(struct.pack("<H", len(frequencies)))
    for word in sorted(frequencies):
        encoded = word.encode("ascii")
        payload.extend(struct.pack("<B", len(encoded)))
        payload.extend(encoded)
        payload.extend(struct.pack("<I", frequencies[word]))

    digest = FNV_OFFSET_BASIS
    for byte in payload:
        digest = ((digest ^ byte) * FNV_PRIME) & ((1 << 64) - 1)
    return digest & MASK63


def _decode_word(values: Sequence[int]) -> tuple[str, str] | None:
    raw_chars: list[str] = []
    folded_chars: list[str] = []
    for value in values:
        if 65 <= value <= 90:
            raw_chars.append(chr(value))
            folded_chars.append(chr(value + 32))
        elif 97 <= value <= 122:
            raw_chars.append(chr(value))
            folded_chars.append(chr(value))
        else:
            return None
    return "".join(raw_chars), "".join(folded_chars)


def _deepest_existing_prefix(key: str, words: dict[str, int]) -> str:
    for length in range(len(key), -1, -1):
        prefix = key[:length]
        if any(word.startswith(prefix) for word in words):
            return prefix
    return ""


def expected_result(
    values: Sequence[int] | None,
    input_length: int | None = None,
    input_is_null: bool = False,
) -> int:
    """Return the low-63 FNV trace hash, or -1 for malformed packed input."""
    if type(input_is_null) is not bool or input_is_null:
        return -1
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return -1
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return -1
    if len(values) > MAX_VALID_INPUT_LENGTH:
        return -1

    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return -1
    offset = 1
    words: dict[str, int] = {}
    observations: list[tuple[int, int | list[str] | None]] = []

    for _ in range(operation_count):
        if offset + 2 > len(values):
            return -1
        opcode, word_length = values[offset], values[offset + 1]
        offset += 2
        if opcode not in (0, 1, 2, 3) or not 0 <= word_length <= MAX_WORD_LENGTH:
            return -1
        if opcode == 0 and word_length == 0:
            return -1
        if offset + word_length > len(values):
            return -1
        decoded = _decode_word(values[offset : offset + word_length])
        if decoded is None:
            return -1
        raw_word, folded_word = decoded
        offset += word_length

        if opcode == 0:
            if folded_word not in words:
                if len(words) >= MAX_UNIQUE_WORDS:
                    return -1
                words[folded_word] = 0
            observations.append((opcode, None))
            continue

        if opcode == 1:
            present = folded_word in words
            if present:
                words[folded_word] += 1
            observations.append((opcode, int(present)))
            continue

        prefix = _deepest_existing_prefix(folded_word, words)
        exact_match = len(prefix) == len(folded_word) and folded_word in words
        suggestions: list[str] = []
        if exact_match:
            words[folded_word] += 1
            suggestions.append(raw_word)
        descendants = [
            word for word in words
            if len(word) > len(prefix) and word.startswith(prefix)
        ]
        if opcode == 2:
            suggestions.extend(sorted(descendants))
        else:
            descendants.sort(key=lambda word: (words[word], word), reverse=True)
            suggestions.extend(descendants[:3])
        observations.append((opcode, suggestions))

    if offset != len(values):
        return -1
    return _hash_trace(operation_count, observations, words)
