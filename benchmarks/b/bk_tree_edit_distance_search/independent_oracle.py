"""Full-scan, full-matrix Levenshtein reference independent of the BK-tree."""

from __future__ import annotations

from collections.abc import Sequence

MAX_WORDS = 16
MAX_QUERIES = 8
MAX_WORD_LENGTH = 10
MAX_RADIUS = 3
MAX_VALID_INPUT_LENGTH = 3 + MAX_WORDS + MAX_QUERIES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_WORKSPACE_BYTES = 4096
INVALID_RESULT = -1


def _valid_word(value: int) -> bool:
    if type(value) is not int or value < 0 or value >= (1 << 44):
        return False
    length = (value >> 40) & 15
    if length > MAX_WORD_LENGTH:
        return False
    for i in range(MAX_WORD_LENGTH):
        symbol = (value >> (4 * i)) & 15
        if (i < length and not 1 <= symbol <= 15) or (i >= length and symbol):
            return False
    return True


def _frame(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63)
                   for x in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    count, query_count, radius = values[:3]
    if (not 0 <= count <= MAX_WORDS or not 0 <= query_count <= MAX_QUERIES
            or not 0 <= radius <= MAX_RADIUS
            or len(values) != 3 + count + query_count):
        return None
    words = values[3:3 + count]
    queries = values[3 + count:]
    if any(not _valid_word(x) for x in words + queries):
        return None
    if len(set(words)) != count:
        return None
    return words, queries, radius


def _full_matrix_distance(first: int, second: int) -> int:
    n = (first >> 40) & 15
    m = (second >> 40) & 15
    table = [[0] * (m + 1) for _ in range(n + 1)]
    for i in range(n + 1):
        table[i][0] = i
    for j in range(m + 1):
        table[0][j] = j
    for i in range(1, n + 1):
        a = (first >> (4 * (i - 1))) & 15
        for j in range(1, m + 1):
            b = (second >> (4 * (j - 1))) & 15
            replacement = table[i - 1][j - 1] + (a != b)
            table[i][j] = min(table[i - 1][j] + 1,
                              table[i][j - 1] + 1, replacement)
    return table[n][m]


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _frame(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    words, queries, radius = parsed
    total = 0
    for query_number, query in enumerate(queries, 1):
        hits = [index for index, word in enumerate(words)
                if _full_matrix_distance(query, word) <= radius]
        total += query_number * (17 * len(hits) + sum(hits))
    return total
