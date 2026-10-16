"""Oracle for the pinned Python DFS/backtracking word ladder variant."""

from __future__ import annotations
import struct

MAX_WORD_LENGTH = 5
MAX_WORDS = 8
MAX_INPUT_LENGTH = 4 + MAX_WORDS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_PATH_WORDS = MAX_WORDS + 1
MAX_OUTPUT_BYTES = 8 * (MAX_PATH_WORDS + MAX_WORDS + 2)
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def encode_word(word: str) -> int:
    code = 0
    for character in word:
        code = code * 26 + (ord(character) - ord("a"))
    return code


def decode_word(code: int, width: int) -> str:
    letters = ["a"] * width
    for position in range(width - 1, -1, -1):
        code, digit = divmod(code, 26)
        letters[position] = chr(ord("a") + digit)
    return "".join(letters)


def solve(values: list[int]) -> tuple[list[int], list[int]] | None:
    if (not isinstance(values, list) or len(values) < 4 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return None
    width, begin, end, count = values[:4]
    if not 1 <= width <= MAX_WORD_LENGTH or not 0 <= count <= MAX_WORDS or len(values) != 4 + count:
        return None
    limit = 26 ** width
    words = values[4:]
    if any(not 0 <= word < limit for word in (begin, end, *words)):
        return None
    if any(words[index - 1] >= words[index] for index in range(1, len(words))):
        return None

    word_set = set(words)

    def backtrack(current: int, path: list[int]) -> list[int]:
        if current == end:
            return path
        for position in range(width):
            factor = 26 ** (width - position - 1)
            digit = (current // factor) % 26
            for replacement in range(26):
                candidate = current + (replacement - digit) * factor
                if candidate in word_set:
                    word_set.remove(candidate)
                    result = backtrack(candidate, [*path, candidate])
                    if result:
                        return result
                    word_set.add(candidate)
        return []

    path = backtrack(begin, [begin]) if end in word_set else []
    remaining = [word for word in words if word in word_set]
    return path, remaining


def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    result = solve(values)
    if result is None:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    path, remaining = result
    encoded = [len(path), *path, len(remaining), *remaining]
    output = b"".join(struct.pack("<q", value) for value in encoded)
    if capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
