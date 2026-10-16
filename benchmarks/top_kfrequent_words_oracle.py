"""Reference ranking for Java's top-k frequent words comparator."""
from __future__ import annotations

MAX_WORDS = 64
MAX_WORD_LENGTH = 16
MAX_INPUT_LENGTH = 2 + MAX_WORDS * (MAX_WORD_LENGTH + 1)


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    k, word_count = values[:2]
    if not 0 <= k <= MAX_WORDS or not 0 <= word_count <= MAX_WORDS:
        return -1, b""
    position = 2
    frequencies: dict[bytes, int] = {}
    for _ in range(word_count):
        if position >= len(values) or not 1 <= values[position] <= MAX_WORD_LENGTH:
            return -1, b""
        word_length = values[position]
        position += 1
        if word_length > len(values) - position:
            return -1, b""
        codes = values[position:position + word_length]
        if any(not 97 <= code <= 122 for code in codes):
            return -1, b""
        word = bytes(codes)
        frequencies[word] = frequencies.get(word, 0) + 1
        position += word_length
    if position != len(values):
        return -1, b""
    ranked = sorted(frequencies, key=lambda word: (-frequencies[word], word))[:k]
    output = b"\n".join(ranked) + b"\0"
    return len(output), output
