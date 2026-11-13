"""Split-and-reverse-lookup oracle for bounded palindrome pairs."""

from __future__ import annotations

from collections.abc import Sequence

MAX_WORDS = 8
MAX_WORD_LENGTH = 8
ALPHABET_SIZE = 4
HASH_CAPACITY = 17
MAX_VALID_INPUT_LENGTH = 1 + MAX_WORDS * (MAX_WORD_LENGTH + 1)
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_WORDS * (MAX_WORDS - 1)
WORKSPACE_BYTES = 4096
MAX_WORKSPACE_BYTES = WORKSPACE_BYTES


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> list[tuple[int, ...]] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
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
    if cursor != len(values):
        return None
    return words


def _encode_reversed(word: Sequence[int], start: int, end: int) -> int:
    key = 1
    for i in range(end - 1, start - 1, -1):
        key = key * 5 + word[i] + 1
    return key


def _is_palindrome(word: Sequence[int], left: int, right: int) -> bool:
    right -= 1
    while left < right:
        if word[left] != word[right]:
            return False
        left += 1
        right -= 1
    return True


def _split_lookup(words: Sequence[Sequence[int]]) -> bytes:
    keys = [0] * HASH_CAPACITY
    heads = [-1] * HASH_CAPACITY
    tails = [-1] * HASH_CAPACITY
    next_word = [-1] * MAX_WORDS

    for word_id, word in enumerate(words):
        key = 1
        for symbol in word:
            key = key * 5 + symbol + 1
        slot = key % HASH_CAPACITY
        while keys[slot] != 0 and keys[slot] != key:
            slot = (slot + 1) % HASH_CAPACITY
        if keys[slot] == 0:
            keys[slot] = key
            heads[slot] = word_id
        else:
            next_word[tails[slot]] = word_id
        tails[slot] = word_id

    found = [[False] * len(words) for _ in words]

    def visit_matches(key: int, fixed_id: int, fixed_on_right: bool) -> None:
        slot = key % HASH_CAPACITY
        while keys[slot] != 0 and keys[slot] != key:
            slot = (slot + 1) % HASH_CAPACITY
        if keys[slot] == 0:
            return
        word_id = heads[slot]
        while word_id >= 0:
            if word_id != fixed_id:
                if fixed_on_right:
                    found[word_id][fixed_id] = True
                else:
                    found[fixed_id][word_id] = True
            word_id = next_word[word_id]

    for word_id, word in enumerate(words):
        size = len(word)
        for split in range(size + 1):
            if _is_palindrome(word, 0, split):
                visit_matches(_encode_reversed(word, split, size), word_id, True)
            if _is_palindrome(word, split, size):
                visit_matches(_encode_reversed(word, 0, split), word_id, False)

    return bytes(left * MAX_WORDS + right
                 for left in range(len(words))
                 for right in range(len(words))
                 if left != right and found[left][right])


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
    payload = _split_lookup(words)
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
