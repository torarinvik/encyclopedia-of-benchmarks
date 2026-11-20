"""Independent per-catalog binary-search verifier for nested catalog queries."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[list[list[int]], list[int]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (tuple, list)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length < 2 or input_length > 147 or input_length != len(values):
        return None
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63) for word in values):
        return None
    m, q = values[0], values[1]
    if m < 2 or m > 8 or q < 1 or q > 8:
        return None
    lists: list[list[int]] = []
    cursor = 2
    for _ in range(m):
        if cursor >= len(values):
            return None
        count = values[cursor]
        cursor += 1
        if count < 1 or count > 16 or cursor + count > len(values):
            return None
        current = list(values[cursor:cursor + count])
        cursor += count
        if any(item < -16 or item > 16 for item in current):
            return None
        if any(current[j - 1] >= current[j] for j in range(1, count)):
            return None
        if lists and not set(current).issubset(set(lists[-1])):
            return None
        lists.append(current)
    if cursor + q != len(values):
        return None
    queries = list(values[cursor:])
    if any(item < -17 or item > 17 for item in queries):
        return None
    return lists, queries


def _direct_successor(catalog: list[int], key: int) -> int:
    for item in catalog:
        if item >= key:
            return item + 17
    return 34


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    catalogs, queries = parsed
    total = 0
    for query_index, key in enumerate(queries, start=1):
        for catalog_index, catalog in enumerate(catalogs, start=1):
            total += query_index * catalog_index * _direct_successor(catalog, key)
    return total
