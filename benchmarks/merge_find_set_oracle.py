"""Independent iterative oracle for the Haskell merge-find-set semantics."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 256
MAX_MERGES = 512
MAX_PARSEABLE_INPUT_LENGTH = 1028
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _root(parent: list[int], element: int) -> int:
    """Follow parent links without changing the forest."""
    while parent[element] != element:
        element = parent[element]
    return element


def expected_result(values: Sequence[int] | None) -> int:
    """Apply ordered merges and return the requested Haskell-style root."""
    if (
        not isinstance(values, (list, tuple))
        or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return -1
    n, merge_count = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= merge_count <= MAX_MERGES:
        return -1
    if len(values) != 2 * merge_count + 3:
        return -1

    parent = list(range(n))
    rank = [0] * n
    position = 2
    for _ in range(merge_count):
        first, second = values[position], values[position + 1]
        position += 2
        if not 0 <= first < n or not 0 <= second < n:
            return -1
        first_root = _root(parent, first)
        second_root = _root(parent, second)
        if first_root == second_root:
            continue
        if rank[first_root] < rank[second_root]:
            parent[first_root] = second_root
        elif rank[first_root] > rank[second_root]:
            parent[second_root] = first_root
        else:
            parent[first_root] = second_root
            rank[second_root] += 1

    query = values[position]
    if not 0 <= query < n:
        return -1
    return _root(parent, query)
