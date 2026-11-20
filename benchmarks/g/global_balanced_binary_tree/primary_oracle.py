"""Primary weighted-midpoint construction for the bounded GBST profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 64
MAX_VALID_INPUT_LENGTH = MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_N + 1
MAX_RESULT = 37_129_297_920
INVALID_RESULT = -1
BASE = 65


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> list[int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != n:
        return None
    parents = [-1] * n
    for vertex in range(1, n):
        parent = values[vertex]
        if not 0 <= parent < vertex:
            return None
        parents[vertex] = parent
    return parents


def _construct(parents: list[int]) -> tuple[list[int], list[int], list[int], list[int]]:
    n = len(parents)
    subtree = [1] * n
    for vertex in range(n - 1, 0, -1):
        subtree[parents[vertex]] += subtree[vertex]

    heavy = [-1] * n
    for vertex in range(1, n):
        parent = parents[vertex]
        current = heavy[parent]
        # Ascending vertex order plus strict comparison keeps the lowest-ID tie.
        if current < 0 or subtree[vertex] > subtree[current]:
            heavy[parent] = vertex

    gbst_parent = [-1] * n
    left_child = [-1] * n
    right_child = [-1] * n
    local_size = [0] * n

    for head in range(n):
        if head != 0 and heavy[parents[head]] == head:
            continue
        path: list[int] = []
        weights: list[int] = []
        vertex = head
        while vertex >= 0:
            path.append(vertex)
            child = heavy[vertex]
            weights.append(subtree[vertex] - (subtree[child] if child >= 0 else 0))
            vertex = child

        prefix = [0]
        for weight in weights:
            prefix.append(prefix[-1] + weight)

        def build(lo: int, hi: int) -> int:
            total_weight = prefix[hi] - prefix[lo]
            low, high = lo, hi
            while high - low > 1:
                middle = (low + high) // 2
                if 2 * (prefix[middle] - prefix[lo]) <= total_weight:
                    low = middle
                else:
                    high = middle
            pivot = low
            node = path[pivot]
            local_size[node] = hi - lo
            if lo < pivot:
                child_root = build(lo, pivot)
                left_child[node] = child_root
                gbst_parent[child_root] = node
            if pivot + 1 < hi:
                child_root = build(pivot + 1, hi)
                right_child[node] = child_root
                gbst_parent[child_root] = node
            return node

        root = build(0, len(path))
        gbst_parent[root] = -1 if head == 0 else parents[head]

    return gbst_parent, left_child, right_child, local_size


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parents = _parse(values, input_is_null, input_length)
    if parents is None:
        return INVALID_RESULT
    gbst_parent, left_child, right_child, local_size = _construct(parents)
    checksum = 0
    for vertex in range(len(parents)):
        record = ((gbst_parent[vertex] + 1)
                  + BASE * (left_child[vertex] + 1)
                  + BASE * BASE * (right_child[vertex] + 1)
                  + BASE * BASE * BASE * local_size[vertex])
        checksum += (vertex + 1) * record
    return checksum
