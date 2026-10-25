"""Independent bounded oracle for Raymond Chen's Ptrdist anagram search."""

from __future__ import annotations

from collections import Counter
from collections.abc import Sequence

MAX_PHRASE_LENGTH = 16
MAX_DICTIONARY_WORDS = 12
MAX_WORD_LENGTH = 16
MAX_INPUT_LENGTH = 222
INVALID_RESULT = -1


def _letter(value: int) -> str | None:
    if 65 <= value <= 90:
        return chr(value + 32)
    if 97 <= value <= 122:
        return chr(value)
    return None


def expected_result(values: Sequence[int] | None, input_length: int | None = None) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 3 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values):
        return INVALID_RESULT

    phrase_length = values[0]
    if not 1 <= phrase_length <= MAX_PHRASE_LENGTH or 1 + phrase_length >= actual_length:
        return INVALID_RESULT
    phrase_chars: list[str] = []
    for value in values[1:1 + phrase_length]:
        char = _letter(value)
        if char is None:
            return INVALID_RESULT
        phrase_chars.append(char)
    phrase_counts = Counter(phrase_chars)
    word_count_offset = phrase_length + 1
    word_count = values[word_count_offset]
    if not 0 <= word_count <= MAX_DICTIONARY_WORDS:
        return INVALID_RESULT

    words: list[str] = []
    offset = word_count_offset + 1
    for _ in range(word_count):
        if offset >= actual_length:
            return INVALID_RESULT
        word_length = values[offset]
        offset += 1
        if not 1 <= word_length <= MAX_WORD_LENGTH or word_length > actual_length - offset:
            return INVALID_RESULT
        chars: list[str] = []
        for value in values[offset:offset + word_length]:
            char = _letter(value)
            if char is None:
                return INVALID_RESULT
            chars.append(char)
        words.append("".join(chars))
        offset += word_length
    if offset != actual_length:
        return INVALID_RESULT

    candidates: list[tuple[str, Counter[str]]] = []
    global_frequency: Counter[str] = Counter()
    for word in words:
        counts = Counter(word)
        if not all(count <= phrase_counts[char] for char, count in counts.items()):
            continue
        if not ((len(word) >= 2 and len(word) + 2 <= phrase_length) or len(word) == phrase_length):
            continue
        candidates.append((word, counts))
        global_frequency.update(counts)

    rarest_first = sorted("abcdefghijklmnopqrstuvwxyz", key=lambda char: (global_frequency[char] or (1 << 32), char))

    def search(remaining: Counter[str], remaining_length: int, start: int, first_letter: int) -> int:
        if remaining_length == 0:
            return 1
        pivot_position = first_letter
        while pivot_position < 26 and remaining[rarest_first[pivot_position]] == 0:
            pivot_position += 1
        if pivot_position == 26:
            return 0
        pivot = rarest_first[pivot_position]
        end = len(candidates)
        solutions = 0
        while start < end:
            word, counts = candidates[start]
            if any(count > remaining[char] for char, count in counts.items()):
                start += 1
                continue
            if counts[pivot] == 0:
                candidates[start], candidates[end - 1] = candidates[end - 1], candidates[start]
                end -= 1
                continue
            next_remaining = remaining.copy()
            next_remaining.subtract(counts)
            solutions += search(next_remaining, remaining_length - len(word), start, pivot_position)
            start += 1
        return solutions

    return search(phrase_counts, phrase_length, 0, 0)
