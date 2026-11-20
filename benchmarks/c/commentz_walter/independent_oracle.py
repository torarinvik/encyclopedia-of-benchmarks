"""Independent direct pattern-at-every-start reference for Commentz-Walter."""

from __future__ import annotations

from collections.abc import Sequence

MAX_PATTERNS = 6
MAX_PATTERN_LENGTH = 8
MAX_TOTAL_PATTERN_LENGTH = 32
MAX_TEXT_LENGTH = 64
MAX_PARSEABLE_INPUT_LENGTH = 105


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    count, text_size = values[0], values[1]
    if not 1 <= count <= MAX_PATTERNS or not 0 <= text_size <= MAX_TEXT_LENGTH:
        return None
    if len(values) < 2 + count:
        return None
    sizes = values[2:2 + count]
    if any(type(size) is not int or size < 1 or size > MAX_PATTERN_LENGTH for size in sizes):
        return None
    total = sum(sizes)
    if total > MAX_TOTAL_PATTERN_LENGTH or len(values) != 2 + count + total + text_size:
        return None
    offset = 2 + count
    patterns: list[tuple[int, ...]] = []
    for size in sizes:
        word = tuple(values[offset:offset + size])
        if any(type(symbol) is not int or symbol < 1 or symbol > 4 for symbol in word):
            return None
        patterns.append(word)
        offset += size
    if len(set(patterns)) != count:
        return None
    text = tuple(values[offset:])
    if len(text) != text_size or any(type(symbol) is not int or symbol < 1 or symbol > 4
                                     for symbol in text):
        return None
    return patterns, text


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return -1
    patterns, text = parsed
    matches = 0
    for pattern in patterns:
        width = len(pattern)
        for start in range(len(text) - width + 1):
            equal = True
            for offset in range(width):
                if text[start + offset] != pattern[offset]:
                    equal = False
                    break
            if equal:
                matches += 1
    return matches
