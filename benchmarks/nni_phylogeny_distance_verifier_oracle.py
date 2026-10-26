"""Independent tree-adjacency verifier for bounded NNI distance."""

from __future__ import annotations

import struct
from collections import deque
from collections.abc import Sequence

MAX_LEAVES = 7
MAX_INPUT = 23


def _valid(splits: Sequence[int], n: int) -> bool:
    edge_count = 2 * n - 3
    universe = (1 << n) - 1
    if len(splits) != edge_count or len(set(splits)) != edge_count:
        return False
    if any(type(split) is not int or split <= 0 or split >= universe or split & 1
           for split in splits):
        return False
    required = {(1 << leaf) for leaf in range(1, n)} | {universe ^ 1}
    if not required.issubset(splits):
        return False
    internal = [split for split in splits if 2 <= split.bit_count() <= n - 2]
    if len(internal) != n - 3:
        return False
    return all(not (left & right) or left & right == left or left & right == right
               for i, left in enumerate(internal) for right in internal[i + 1:])


def _tree(n: int, splits: Sequence[int]) -> list[set[int]]:
    clusters = sorted((split for split in splits
                       if 2 <= split.bit_count() <= n - 2),
                      key=lambda mask: (mask.bit_count(), mask))
    root = n + len(clusters)
    adjacency = [set() for _ in range(root + 1)]

    def connect(left: int, right: int) -> None:
        adjacency[left].add(right)
        adjacency[right].add(left)

    for index, cluster in enumerate(clusters):
        supersets = [other for other in clusters
                     if cluster != other and cluster & other == cluster]
        parent_cluster = min(supersets, key=int.bit_count) if supersets else None
        parent = n + clusters.index(parent_cluster) if parent_cluster is not None else root
        connect(parent, n + index)
    for leaf in range(1, n):
        containing = [cluster for cluster in clusters if cluster & (1 << leaf)]
        parent_cluster = min(containing, key=int.bit_count) if containing else None
        parent = n + clusters.index(parent_cluster) if parent_cluster is not None else root
        connect(parent, leaf)
    connect(root, 0)
    return adjacency


def _split_state(adjacency: list[set[int]], n: int) -> tuple[int, ...]:
    universe = (1 << n) - 1
    masks = []
    for left, neighbors in enumerate(adjacency):
        for right in neighbors:
            if left >= right:
                continue
            stack = [left]
            visited = {right}
            leaf_mask = 0
            while stack:
                node = stack.pop()
                if node in visited:
                    continue
                visited.add(node)
                if node < n:
                    leaf_mask |= 1 << node
                stack.extend(adjacency[node] - visited)
            masks.append(universe ^ leaf_mask if leaf_mask & 1 else leaf_mask)
    return tuple(sorted(masks))


def _neighbors(state: Sequence[int], n: int):
    adjacency = _tree(n, state)
    internals = range(n, len(adjacency))
    for left in internals:
        for right in adjacency[left]:
            if right < n or left >= right:
                continue
            left_branches = sorted(adjacency[left] - {right})
            right_branches = sorted(adjacency[right] - {left})
            for right_branch in right_branches:
                changed = [set(row) for row in adjacency]
                a, b = left_branches[0], right_branch
                changed[left].remove(a)
                changed[a].remove(left)
                changed[right].remove(b)
                changed[b].remove(right)
                changed[left].add(b)
                changed[b].add(left)
                changed[right].add(a)
                changed[a].add(right)
                yield _split_state(changed, n)


def _distance(n: int, first: Sequence[int], second: Sequence[int]) -> int:
    start = tuple(sorted(first))
    goal = tuple(sorted(second))
    distances = {start: 0}
    queue = deque([start])
    while queue:
        state = queue.popleft()
        if state == goal:
            return distances[state]
        for neighbor in _neighbors(state, n):
            if neighbor not in distances:
                distances[neighbor] = distances[state] + 1
                queue.append(neighbor)
    return -1


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    if (not isinstance(values, (tuple, list)) or not 7 <= len(values) <= MAX_INPUT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n = values[0]
    if not 3 <= n <= MAX_LEAVES:
        return -1, b""
    edges = 2 * n - 3
    if len(values) != 1 + 2 * edges:
        return -1, b""
    first, second = values[1:1 + edges], values[1 + edges:]
    if not _valid(first, n) or not _valid(second, n):
        return -1, b""
    payload = struct.pack("<q", _distance(n, first, second))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
