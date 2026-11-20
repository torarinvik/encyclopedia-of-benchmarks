"""Independent GBST reference using descendant walks and linear pivots."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 64
MAX_VALID_INPUT_LENGTH = MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_N + 1
INVALID_RESULT = -1
BASE = 65


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[list[int], list[list[int]]] | None:
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
    children = [[] for _ in range(n)]
    for vertex in range(1, n):
        parent = values[vertex]
        if not 0 <= parent < vertex:
            return None
        parents[vertex] = parent
        children[parent].append(vertex)
    return parents, children


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    parents, children = parsed
    n = len(parents)

    # Count a candidate subtree by following each vertex's ancestor chain.
    subtree = [0] * n
    for descendant in range(n):
        ancestor = descendant
        while ancestor >= 0:
            subtree[ancestor] += 1
            ancestor = parents[ancestor]

    heavy = [-1] * n
    for vertex in range(n):
        best_size = -1
        best_child = -1
        for child in children[vertex]:
            if (subtree[child] > best_size
                    or (subtree[child] == best_size and child < best_child)):
                best_size = subtree[child]
                best_child = child
        heavy[vertex] = best_child

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
            pivot = lo
            included_weight = weights[lo]
            while (pivot + 1 < hi
                   and 2 * included_weight <= total_weight):
                pivot += 1
                included_weight += weights[pivot]
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

    checksum = 0
    for vertex in range(n):
        record = ((gbst_parent[vertex] + 1)
                  + BASE * (left_child[vertex] + 1)
                  + BASE * BASE * (right_child[vertex] + 1)
                  + BASE * BASE * BASE * local_size[vertex])
        checksum += (vertex + 1) * record
    return checksum
