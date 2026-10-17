"""Oracle for the bounded shortest-word-distance benchmark."""

from __future__ import annotations

from collections.abc import Sequence

MAX_WORDS = 32
MAX_WORD_LENGTH = 8
MAX_INPUT_LENGTH = 1 + MAX_WORDS * (MAX_WORD_LENGTH + 1) + 2 * (MAX_WORD_LENGTH + 1)
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: Sequence[int] | None, input_is_null: bool = False, input_length: int | None = None) -> int:
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT
    if input_is_null:
        if (not isinstance(values, (list, tuple)) or values or type(input_length) is not int
                or not 1 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
            return INVALID_RESULT
        return INVALID_RESULT
    if values is None or not isinstance(values, (list, tuple)) or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    count = values[0]
    if not 2 <= count <= MAX_WORDS:
        return INVALID_RESULT
    position = 1
    words: list[bytes] = []
    for _ in range(count):
        if position >= len(values):
            return INVALID_RESULT
        size = values[position]
        position += 1
        if not 1 <= size <= MAX_WORD_LENGTH or position + size > len(values):
            return INVALID_RESULT
        raw = values[position:position + size]
        if any(not (65 <= byte <= 90 or 97 <= byte <= 122) for byte in raw):
            return INVALID_RESULT
        words.append(bytes(raw))
        position += size
    targets: list[bytes] = []
    for _ in range(2):
        if position >= len(values):
            return INVALID_RESULT
        size = values[position]
        position += 1
        if not 1 <= size <= MAX_WORD_LENGTH or position + size > len(values):
            return INVALID_RESULT
        raw = values[position:position + size]
        if any(not (65 <= byte <= 90 or 97 <= byte <= 122) for byte in raw):
            return INVALID_RESULT
        targets.append(bytes(raw))
        position += size
    if position != len(values):
        return INVALID_RESULT
    first, second = targets
    if first == second or first not in words or second not in words:
        return INVALID_RESULT
    return min(abs(i - j) for i, word in enumerate(words) for j, other in enumerate(words)
               if (word == first and other == second) or (word == second and other == first))
