"""Rank by enumerating distinct lexicographic arrangements of the multiset."""

from __future__ import annotations

from collections.abc import Sequence

MAX_LENGTH = 8
MAX_SYMBOL = 25
MAX_PARSEABLE_INPUT_LENGTH = 10
INVALID_RESULT = -1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, ...] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    count = values[0]
    if not 0 <= count <= MAX_LENGTH or len(values) != count + 1:
        return None
    symbols = tuple(values[1:])
    if any(symbol < 0 or symbol > MAX_SYMBOL for symbol in symbols):
        return None
    return symbols


def _next_multiset_permutation(word: list[int]) -> bool:
    pivot = len(word) - 2
    while pivot >= 0 and word[pivot] >= word[pivot + 1]:
        pivot -= 1
    if pivot < 0:
        return False
    successor = len(word) - 1
    while word[successor] <= word[pivot]:
        successor -= 1
    word[pivot], word[successor] = word[successor], word[pivot]
    word[pivot + 1:] = reversed(word[pivot + 1:])
    return True


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    target = _decode(values, input_is_null, input_length)
    if target is None:
        return INVALID_RESULT
    current = sorted(target)
    rank = 1
    while tuple(current) != target:
        if not _next_multiset_permutation(current):
            return INVALID_RESULT
        rank += 1
    return rank
