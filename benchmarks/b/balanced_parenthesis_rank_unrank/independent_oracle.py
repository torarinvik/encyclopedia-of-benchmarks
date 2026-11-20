"""Exhaustive lexicographic Dyck-word enumeration for rank and unrank."""

from __future__ import annotations

from itertools import combinations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_PAIRS = 10
MAX_VALID_INPUT_LENGTH = 22
MAX_PARSEABLE_INPUT_LENGTH = 23


def _decode(values, input_is_null, input_length):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values) or len(values) < 2:
        return None
    mode, pairs = values[:2]
    if type(mode) is not int or type(pairs) is not int or not 1 <= pairs <= MAX_PAIRS:
        return None
    if mode == 0:
        if len(values) != 2 + 2 * pairs:
            return None
        symbols = tuple(values[2:])
        if any(symbol not in (0, 1) for symbol in symbols):
            return None
        balance = 0
        for symbol in symbols:
            balance += 1 if symbol == 0 else -1
            if balance < 0:
                return None
        if balance != 0:
            return None
        return mode, pairs, symbols, None
    if mode == 1 and len(values) == 3:
        return mode, pairs, None, values[2]
    return None


def _valid_words(pairs):
    length = 2 * pairs
    for opens in combinations(range(length), pairs):
        opening_positions = set(opens)
        word = tuple(0 if i in opening_positions else 1 for i in range(length))
        balance = 0
        for symbol in word:
            balance += 1 if symbol == 0 else -1
            if balance < 0:
                break
        else:
            if balance == 0:
                yield word


def expected_result(values, input_is_null=False, input_length=None):
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    mode, pairs, wanted, requested_rank = decoded
    if mode == 0:
        for rank, word in enumerate(_valid_words(pairs)):
            if word == wanted:
                return rank
        return -1
    if requested_rank < 0:
        return -1
    for rank, word in enumerate(_valid_words(pairs)):
        if rank == requested_rank:
            code = 0
            for symbol in word:
                code = (code << 1) | symbol
            return code
    return -1
