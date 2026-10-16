"""Reference for first-seen words occurring once across two sentences."""
from __future__ import annotations

MAX_WORDS = 64
MAX_WORD_LENGTH = 16
MAX_INPUT_LENGTH = 1 + MAX_WORDS * (MAX_WORD_LENGTH + 1)


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(v) is not int or not -(2**63) <= v < 2**63 for v in values)):
        return -1, b""
    count = values[0]
    if not 0 <= count <= MAX_WORDS:
        return -1, b""
    pos = 1
    frequencies: dict[bytes, int] = {}
    for _ in range(count):
        if pos >= len(values) or not 1 <= values[pos] <= MAX_WORD_LENGTH:
            return -1, b""
        size = values[pos]
        pos += 1
        if size > len(values) - pos:
            return -1, b""
        codes = values[pos:pos + size]
        if any(not 97 <= c <= 122 for c in codes):
            return -1, b""
        word = bytes(codes)
        frequencies[word] = frequencies.get(word, 0) + 1
        pos += size
    if pos != len(values):
        return -1, b""
    selected = [word for word, n in frequencies.items() if n == 1]
    result = b"\n".join(selected) + b"\0"
    return len(result), result
