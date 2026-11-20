"""Independent binary-lifting reference for the bounded tree LCA contract."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MAX_NODES = 256
MAX_QUERIES = 1024
MAX_INPUT_VALUES = 4 + 2 * (MAX_NODES - 1) + 2 * MAX_QUERIES
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_VALUES + 1
MAX_OUTPUT_BYTES = MAX_QUERIES
MAX_WORKSPACE_BYTES = 32_768


def _parse(values: Sequence[int] | None, input_is_null: bool, input_length: int | None):
    if (
        input_is_null
        or not isinstance(values, (list, tuple))
        or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or (input_length is not None and (type(input_length) is not int or input_length != len(values)))
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return None
    n, root, edge_count, query_count = values[:4]
    if not 1 <= n <= MAX_NODES or not 0 <= root < n or edge_count != n - 1:
        return None
    if not 0 <= query_count <= MAX_QUERIES:
        return None
    query_offset = 4 + 2 * edge_count
    if len(values) != query_offset + 2 * query_count:
        return None
    graph: list[list[int]] = [[] for _ in range(n)]
    for edge in range(edge_count):
        left, right = values[4 + 2 * edge : 6 + 2 * edge]
        if not (0 <= left < n and 0 <= right < n) or left == right:
            return None
        graph[left].append(right)
        graph[right].append(left)
    pairs: list[tuple[int, int]] = []
    for query in range(query_count):
        left, right = values[query_offset + 2 * query : query_offset + 2 * query + 2]
        if not (0 <= left < n and 0 <= right < n):
            return None
        pairs.append((left, right))

    parent = [root] * n
    depth = [0] * n
    seen = [False] * n
    seen[root] = True
    queue = deque([root])
    while queue:
        node = queue.popleft()
        for neighbor in graph[node]:
            if neighbor == parent[node] and node != root:
                continue
            if seen[neighbor]:
                return None
            seen[neighbor] = True
            parent[neighbor] = node
            depth[neighbor] = depth[node] + 1
            queue.append(neighbor)
    if not all(seen):
        return None

    levels = n.bit_length()
    ancestors = [parent]
    for _ in range(1, levels):
        previous = ancestors[-1]
        ancestors.append([previous[previous[node]] for node in range(n)])
    return depth, ancestors, pairs


def _lca(left: int, right: int, depth: list[int], ancestors: list[list[int]]) -> int:
    if depth[left] < depth[right]:
        left, right = right, left
    difference = depth[left] - depth[right]
    bit = 0
    while difference:
        if difference & 1:
            left = ancestors[bit][left]
        difference >>= 1
        bit += 1
    if left == right:
        return left
    for level in range(len(ancestors) - 1, -1, -1):
        if ancestors[level][left] != ancestors[level][right]:
            left = ancestors[level][left]
            right = ancestors[level][right]
    return ancestors[0][left]


def verify_result(
    values: Sequence[int] | None,
    result: int,
    output: bytes,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> bool:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return result == -1 and output == b""
    depth, ancestors, pairs = parsed
    capacity = MAX_QUERIES if output_capacity is None else output_capacity
    if type(output_is_null) is not bool or type(capacity) is not int or capacity < 0:
        return result == -2 and output == b""
    if capacity < len(pairs) or (output_is_null and pairs):
        return result == -2 and output == b""
    if not isinstance(output, (bytes, bytearray)) or result != len(pairs) or len(output) != len(pairs):
        return False
    expected = bytes(_lca(left, right, depth, ancestors) for left, right in pairs)
    return bytes(output) == expected


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    depth, ancestors, pairs = parsed
    actual_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(actual_capacity) is not int
            or actual_capacity < 0):
        return -2, b""
    if actual_capacity < len(pairs) or (output_is_null and pairs):
        return -2, b""
    output = bytes(_lca(left, right, depth, ancestors) for left, right in pairs)
    return len(output), output
