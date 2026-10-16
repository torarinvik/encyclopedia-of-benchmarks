"""Independent scalar oracle for the pinned Go transposition cipher."""

from __future__ import annotations

OFFSET = 14695981039346656037
PRIME = 1099511628211
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1
MAX_KEY = 32
MAX_TEXT = 512
MAX_INPUT = 3 + MAX_KEY + MAX_TEXT


def _hash_runes(text: str) -> int:
    digest = OFFSET
    words = [len(text)]
    words.extend(ord(char) for char in text)
    for index, word in enumerate(words):
        width = 8 if index == 0 else 4
        for shift in range(0, width * 8, 8):
            digest = ((digest ^ ((word >> shift) & 0xFF)) * PRIME) & MASK64
    return digest & MASK63


def _key_ranks(key: str) -> list[int]:
    lowered = key.lower()
    sorted_key = sorted(lowered)
    used: dict[str, int] = {}
    ranks: list[int] = []
    for char in lowered:
        ranks.append(sorted_key.index(char) + used.get(char, 0) + 1)
        used[char] = used.get(char, 0) + 1
    return ranks


def _encrypt(text: str, key: str) -> str:
    ranks = _key_ranks(key)
    width = len(ranks)
    padding = width - (len(text) % width)
    padded = text + (" " * padding)
    result: list[str] = []
    for start in range(0, len(padded), width):
        block = padded[start:start + width]
        columns = [""] * width
        for offset, char in enumerate(block):
            columns[ranks[offset] - 1] = char
        result.extend(columns)
    return "".join(result)


def _decrypt(text: str, key: str) -> str:
    ranks = _key_ranks(key)
    width = len(ranks)
    padding = width - (len(text) % width)
    padded = text + (" " * padding)
    result: list[str] = []
    for start in range(0, len(text), width):
        block = padded[start:start + width]
        row = [""] * width
        for offset, rank in enumerate(ranks):
            row[offset] = block[rank - 1]
        result.extend(row)
    return "".join(result).rstrip(" ")


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 3 or
            len(values) > MAX_INPUT or
            any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                for value in values)):
        return -1
    mode, key_length = values[0], values[1]
    if mode not in (0, 1) or not 1 <= key_length <= MAX_KEY:
        return -1
    key_end = 2 + key_length
    if len(values) <= key_end:
        return -1
    text_length = values[key_end]
    if not 1 <= text_length <= MAX_TEXT or len(values) != key_end + 1 + text_length:
        return -1
    key_bytes = values[2:key_end]
    text_bytes = values[key_end + 1:]
    if any(not (65 <= byte <= 90 or 97 <= byte <= 122) for byte in key_bytes):
        return -1
    if any(not 32 <= byte <= 126 for byte in text_bytes):
        return -1
    key = "".join(chr(byte) for byte in key_bytes)
    text = "".join(chr(byte) for byte in text_bytes)
    if mode == 0 and text.endswith(" "):
        return -1
    output = _encrypt(text, key) if mode == 0 else _decrypt(text, key)
    return _hash_runes(output)
