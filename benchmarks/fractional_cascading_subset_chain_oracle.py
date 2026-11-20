"""Primary bridge-traversal oracle for a bounded nested catalog chain."""

from __future__ import annotations

from collections.abc import Sequence

MIN_CATALOGS = 2
MAX_CATALOGS = 8
MIN_QUERIES = 1
MAX_QUERIES = 8
MAX_CATALOG_SIZE = 16
KEY_MIN = -16
KEY_MAX = 16
QUERY_MIN = -17
QUERY_MAX = 17
MAX_VALID_INPUT_LENGTH = 146
MAX_PARSEABLE_INPUT_LENGTH = 147
INVALID_RESULT = -1
NO_SUCCESSOR_CODE = 34


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[list[list[int]], list[int]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 2
            or input_length > MAX_PARSEABLE_INPUT_LENGTH or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    m, q = values[0], values[1]
    if not MIN_CATALOGS <= m <= MAX_CATALOGS or not MIN_QUERIES <= q <= MAX_QUERIES:
        return None
    catalogs: list[list[int]] = []
    offset = 2
    for _ in range(m):
        if offset >= input_length:
            return None
        size = values[offset]
        offset += 1
        if not 1 <= size <= MAX_CATALOG_SIZE or offset + size > input_length:
            return None
        catalog = list(values[offset:offset + size])
        offset += size
        if any(key < KEY_MIN or key > KEY_MAX for key in catalog):
            return None
        if any(catalog[i - 1] >= catalog[i] for i in range(1, size)):
            return None
        if catalogs:
            parent = catalogs[-1]
            parent_index = 0
            for key in catalog:
                while parent_index < len(parent) and parent[parent_index] < key:
                    parent_index += 1
                if parent_index == len(parent) or parent[parent_index] != key:
                    return None
                parent_index += 1
        catalogs.append(catalog)
    if offset + q != input_length:
        return None
    queries = list(values[offset:offset + q])
    if any(key < QUERY_MIN or key > QUERY_MAX for key in queries):
        return None
    return catalogs, queries


def _lower_bound(catalog: list[int], key: int) -> int:
    low, high = 0, len(catalog)
    while low < high:
        middle = (low + high) // 2
        if catalog[middle] < key:
            low = middle + 1
        else:
            high = middle
    return low


def _bridge(parent: list[int], child: list[int]) -> list[int]:
    """Map every parent lower-bound slot to the matching child lower-bound slot."""
    result = [0] * (len(parent) + 1)
    child_index = 0
    for parent_index, key in enumerate(parent):
        while child_index < len(child) and child[child_index] < key:
            child_index += 1
        result[parent_index] = child_index
    result[len(parent)] = len(child)
    return result


def _checksum(catalogs: list[list[int]], queries: list[int]) -> int:
    bridges = [_bridge(catalogs[i], catalogs[i + 1]) for i in range(len(catalogs) - 1)]
    total = 0
    for query_index, key in enumerate(queries, start=1):
        position = _lower_bound(catalogs[0], key)
        for catalog_index, catalog in enumerate(catalogs):
            code = catalog[position] + 17 if position < len(catalog) else NO_SUCCESSOR_CODE
            total += query_index * (catalog_index + 1) * code
            if catalog_index + 1 < len(catalogs):
                position = bridges[catalog_index][position]
    return total


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    catalogs, queries = parsed
    return _checksum(catalogs, queries)
