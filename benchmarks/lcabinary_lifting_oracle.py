"""Oracle for the bounded lowest-common-ancestor query workload."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MAX_NODES = 128
MAX_QUERIES = 256
MAX_VALID_INPUT_VALUES = 770
MAX_PARSEABLE_INPUT_VALUES = 771
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None) -> int:
    """Return the weighted LCA checksum, or -1 for invalid input."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_PARSEABLE_INPUT_VALUES
        or len(values) < 4
        or any(
            type(value) is not int or not I64_MIN <= value <= I64_MAX
            for value in values
        )
    ):
        return INVALID_RESULT

    node_count, root, edge_count = values[:3]
    if not 2 <= node_count <= MAX_NODES or not 0 <= root < node_count:
        return INVALID_RESULT
    if edge_count != node_count - 1:
        return INVALID_RESULT

    cursor = 3
    if cursor + 2 * edge_count + 1 > len(values):
        return INVALID_RESULT
    adjacency = [set() for _ in range(node_count)]
    parent = list(range(node_count))
    rank = [0] * node_count

    def find(item: int) -> int:
        while parent[item] != item:
            parent[item] = parent[parent[item]]
            item = parent[item]
        return item

    for _ in range(edge_count):
        left, right = values[cursor : cursor + 2]
        cursor += 2
        if not 0 <= left < node_count or not 0 <= right < node_count or left == right:
            return INVALID_RESULT
        left_root = find(left)
        right_root = find(right)
        if left_root == right_root:
            return INVALID_RESULT
        if rank[left_root] < rank[right_root]:
            parent[left_root] = right_root
        elif rank[left_root] > rank[right_root]:
            parent[right_root] = left_root
        else:
            parent[right_root] = left_root
            rank[left_root] += 1
        adjacency[left].add(right)
        adjacency[right].add(left)

    if len({find(node) for node in range(node_count)}) != 1:
        return INVALID_RESULT

    query_count = values[cursor]
    cursor += 1
    if not 0 <= query_count <= MAX_QUERIES:
        return INVALID_RESULT
    if cursor + 2 * query_count > len(values):
        return INVALID_RESULT

    depth = [-1] * node_count
    ancestors = [-1] * node_count
    depth[root] = 0
    ancestors[root] = root
    queue = deque([root])
    while queue:
        node = queue.popleft()
        for child in adjacency[node]:
            if child == ancestors[node]:
                continue
            ancestors[child] = node
            depth[child] = depth[node] + 1
            queue.append(child)

    checksum = 0
    for query_index in range(query_count):
        first, second = values[cursor : cursor + 2]
        cursor += 2
        if not 0 <= first < node_count or not 0 <= second < node_count:
            return INVALID_RESULT
        left, right = first, second
        while depth[left] > depth[right]:
            left = ancestors[left]
        while depth[right] > depth[left]:
            right = ancestors[right]
        while left != right:
            left = ancestors[left]
            right = ancestors[right]
        checksum += (query_index + 1) * (left + 1)

    if cursor != len(values):
        return INVALID_RESULT
    return checksum
