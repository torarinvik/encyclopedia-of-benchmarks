"""Exhaustive tableau-pair enumeration with reverse row insertion."""

from collections import defaultdict
from functools import lru_cache

from .primary_oracle import (
    BASE,
    INVALID,
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
)


def _tableau_words(n):
    by_shape = defaultdict(list)

    def grow(row_lengths, row_word):
        if len(row_word) == n:
            by_shape[tuple(row_lengths)].append(tuple(row_word))
            return
        for row in range(len(row_lengths) + 1):
            if row == len(row_lengths):
                row_lengths.append(1)
                row_word.append(row)
                grow(row_lengths, row_word)
                row_word.pop()
                row_lengths.pop()
            elif row == 0 or row_lengths[row] < row_lengths[row - 1]:
                row_lengths[row] += 1
                row_word.append(row)
                grow(row_lengths, row_word)
                row_word.pop()
                row_lengths[row] -= 1

    grow([], [])
    return by_shape


def _rows_from_word(word, n):
    row_count = max(word, default=-1) + 1
    rows = [[] for _ in range(row_count)]
    for label, row in enumerate(word, start=1):
        rows[row].append(label)
    return rows


def _reverse_pair_to_permutation(p_word, q_word, n):
    p_rows = _rows_from_word(p_word, n)
    q_rows = _rows_from_word(q_word, n)
    permutation = [-1] * n
    for step in range(n, 0, -1):
        row = q_word[step - 1]
        if not q_rows[row] or q_rows[row][-1] != step or not p_rows[row]:
            return None
        q_rows[row].pop()
        value = p_rows[row].pop()
        for upper in range(row - 1, -1, -1):
            column = len(p_rows[upper]) - 1
            while column >= 0 and p_rows[upper][column] >= value:
                column -= 1
            if column < 0:
                return None
            p_rows[upper][column], value = value, p_rows[upper][column]
        permutation[step - 1] = value - 1
    return tuple(permutation)


@lru_cache(maxsize=None)
def _pair_codes_by_input(n):
    if n == 0:
        return {(): 0}
    tableaux_by_shape = _tableau_words(n)
    codes = {}
    for words in tableaux_by_shape.values():
        for p_word in words:
            for q_word in words:
                permutation = _reverse_pair_to_permutation(p_word, q_word, n)
                if permutation is None:
                    continue
                code = n
                for p_row, q_row in zip(p_word, q_word):
                    code = code * BASE + p_row + 1
                    code = code * BASE + q_row + 1
                codes[permutation] = code
    return codes


def expected_result(values, input_is_null=False, input_length=None):
    if type(input_is_null) is not bool:
        return INVALID
    if input_length is not None and (
        type(input_length) is not int
        or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
    ):
        return INVALID
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID
    if input_length is not None and input_length != len(values):
        return INVALID
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return INVALID
    n = values[0]
    if type(n) is not int or not 0 <= n <= MAX_N or len(values) != n + 1:
        return INVALID
    permutation = tuple(values[1:])
    if sorted(permutation) != list(range(n)):
        return INVALID
    return _pair_codes_by_input(n).get(permutation, INVALID)
