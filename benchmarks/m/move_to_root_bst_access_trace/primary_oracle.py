"""Array-backed move-to-root BST trace reference."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INITIAL_KEYS = 16
MAX_ACCESSES = 32
MAX_VALID_INPUT_LENGTH = 2 + MAX_INITIAL_KEYS + MAX_ACCESSES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
WORKSPACE_BYTES = 4096
MIN_KEY = -100
MAX_KEY = 100
MAX_RESULT = 8448
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> tuple[list[int], list[int]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    declared_length = len(values) if input_length is None else input_length
    if type(declared_length) is not int or declared_length != len(values):
        return None
    initial_count = values[0]
    if not 0 <= initial_count <= MAX_INITIAL_KEYS:
        return None
    query_offset = 1 + initial_count
    if len(values) < query_offset + 1:
        return None
    access_count = values[query_offset]
    if not 0 <= access_count <= MAX_ACCESSES or len(values) != query_offset + 1 + access_count:
        return None
    initial = list(values[1:query_offset])
    queries = list(values[query_offset + 1:])
    if (any(not MIN_KEY <= key <= MAX_KEY for key in initial + queries)
            or len(set(initial)) != len(initial)):
        return None
    return initial, queries


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return the query-index-weighted number of comparisons before each access rotates."""
    parsed = _decode(values, input_length, input_is_null)
    if parsed is None:
        return -1
    initial, queries = parsed

    keys = [0] * MAX_INITIAL_KEYS
    left = [-1] * MAX_INITIAL_KEYS
    right = [-1] * MAX_INITIAL_KEYS
    parent = [-1] * MAX_INITIAL_KEYS
    root = -1
    for index, key in enumerate(initial):
        keys[index] = key
        if root == -1:
            root = index
            continue
        current = root
        while True:
            if key < keys[current]:
                if left[current] == -1:
                    left[current] = index
                    parent[index] = current
                    break
                current = left[current]
            else:
                if right[current] == -1:
                    right[current] = index
                    parent[index] = current
                    break
                current = right[current]

    score = 0
    for query_number, query in enumerate(queries, 1):
        current = root
        comparisons = 0
        while current != -1:
            comparisons += 1
            if query == keys[current]:
                break
            current = left[current] if query < keys[current] else right[current]
        if current != -1:
            node = current
            while parent[node] != -1:
                old_parent = parent[node]
                grandparent = parent[old_parent]
                if left[old_parent] == node:
                    middle = right[node]
                    right[node] = old_parent
                    left[old_parent] = middle
                    if middle != -1:
                        parent[middle] = old_parent
                else:
                    middle = left[node]
                    left[node] = old_parent
                    right[old_parent] = middle
                    if middle != -1:
                        parent[middle] = old_parent
                parent[old_parent] = node
                parent[node] = grandparent
                if grandparent == -1:
                    root = node
                elif left[grandparent] == old_parent:
                    left[grandparent] = node
                else:
                    right[grandparent] = node
        score += query_number * comparisons
    return score
