"""Direct ordered-pair concatenation checks for palindrome-pair fixtures."""

from __future__ import annotations

from collections.abc import Sequence

MAX_WORDS = 8
MAX_WORD_LENGTH = 8
ALPHABET_SIZE = 4
MAX_VALID_INPUT_LENGTH = 1 + MAX_WORDS * (MAX_WORD_LENGTH + 1)
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_WORDS * (MAX_WORDS - 1)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> list[tuple[int, ...]] | None:
    if input_is_null or not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    count = values[0]
    if not 0 <= count <= MAX_WORDS:
        return None
    words: list[tuple[int, ...]] = []
    cursor = 1
    for _ in range(count):
        if cursor >= len(values):
            return None
        size = values[cursor]
        cursor += 1
        if not 0 <= size <= MAX_WORD_LENGTH or cursor + size > len(values):
            return None
        word = tuple(values[cursor:cursor + size])
        if any(not 0 <= symbol < ALPHABET_SIZE for symbol in word):
            return None
        words.append(word)
        cursor += size
    return words if cursor == len(values) else None


def _char_at(first: Sequence[int], second: Sequence[int], position: int) -> int:
    return first[position] if position < len(first) else second[position - len(first)]


def _joined_palindrome(first: Sequence[int], second: Sequence[int]) -> bool:
    total = len(first) + len(second)
    for left in range(total // 2):
        right = total - 1 - left
        if _char_at(first, second, left) != _char_at(first, second, right):
            return False
    return True


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    words = _parse(values, input_is_null, input_length)
    if words is None:
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    payload = bytes(left * MAX_WORDS + right
                    for left, first in enumerate(words)
                    for right, second in enumerate(words)
                    if left != right and _joined_palindrome(first, second))
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
