"""Static x-fast prefix-directory oracle for batched integer predecessor queries."""

from __future__ import annotations

from collections.abc import Sequence

MAX_KEYS = 24
MAX_QUERIES = 24
UNIVERSE_BITS = 16
MAX_VALID_INPUT_LENGTH = 2 + MAX_KEYS + MAX_QUERIES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[list[int], list[int]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length < 2
            or actual_length > MAX_PARSEABLE_INPUT_LENGTH or actual_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    key_count, query_count = values[0], values[1]
    if not 0 <= key_count <= MAX_KEYS or not 0 <= query_count <= MAX_QUERIES:
        return None
    if actual_length != 2 + key_count + query_count:
        return None
    keys = list(values[2:2 + key_count])
    queries = list(values[2 + key_count:])
    if any(not 0 <= key < (1 << UNIVERSE_BITS) for key in keys + queries):
        return None
    if len(set(keys)) != len(keys):
        return None
    keys.sort()
    return keys, queries


def _prefix(key: int, depth: int) -> int:
    return 0 if depth == 0 else key >> (UNIVERSE_BITS - depth)


def _find_prefix(levels: list[list[int]], depth: int, value: int) -> int:
    row = levels[depth]
    low, high = 0, len(row)
    while low < high:
        middle = (low + high) // 2
        if row[middle] < value:
            low = middle + 1
        else:
            high = middle
    return low if low < len(row) and row[low] == value else -1


def _x_fast_predecessor(keys: list[int], query: int) -> int:
    if not keys:
        return -1
    levels: list[list[int]] = [[] for _ in range(UNIVERSE_BITS + 1)]
    level_maxima: list[list[int]] = [[] for _ in range(UNIVERSE_BITS + 1)]
    for depth in range(UNIVERSE_BITS + 1):
        for key in keys:
            value = _prefix(key, depth)
            if not levels[depth] or levels[depth][-1] != value:
                levels[depth].append(value)
                level_maxima[depth].append(key)
            else:
                level_maxima[depth][-1] = key

    low, high = 0, UNIVERSE_BITS + 1
    while high - low > 1:
        middle = (low + high) // 2
        if _find_prefix(levels, middle, _prefix(query, middle)) >= 0:
            low = middle
        else:
            high = middle
    if low == UNIVERSE_BITS:
        return query

    for depth in range(low + 1, 0, -1):
        query_prefix = _prefix(query, depth)
        if query_prefix & 1:
            left_sibling = query_prefix - 1
            position = _find_prefix(levels, depth, left_sibling)
            if position >= 0:
                return level_maxima[depth][position]
    return -1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    keys, queries = parsed
    checksum = 0
    for index, query in enumerate(queries):
        checksum += (index + 1) * (_x_fast_predecessor(keys, query) + 1)
    return checksum
