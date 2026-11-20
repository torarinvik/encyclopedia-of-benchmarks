"""Source-shaped Schieber–Vishkin reference for bounded tree LCA batches."""

from __future__ import annotations

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
    adjacency: list[list[int]] = [[] for _ in range(n)]
    for edge in range(edge_count):
        u, v = values[4 + 2 * edge : 6 + 2 * edge]
        if not (0 <= u < n and 0 <= v < n) or u == v:
            return None
        adjacency[u].append(v)
        adjacency[v].append(u)
    queries: list[tuple[int, int]] = []
    for query in range(query_count):
        u, v = values[query_offset + 2 * query : query_offset + 2 * query + 2]
        if not (0 <= u < n and 0 <= v < n):
            return None
        queries.append((u, v))

    parent = [-2] * n
    preorder = [0] * n
    order: list[int] = []
    parent[root] = -1
    preorder[root] = 1
    order.append(root)
    stack = [root]
    while stack:
        node = stack.pop()
        for neighbor in adjacency[node]:
            if neighbor == parent[node]:
                continue
            if parent[neighbor] != -2:
                return None
            parent[neighbor] = node
            preorder[neighbor] = len(order) + 1
            order.append(neighbor)
            stack.append(neighbor)
    if len(order) != n:
        return None
    return adjacency, parent, preorder, order, queries


def _lowbit(value: int) -> int:
    return value & -value


def _highbit(value: int) -> int:
    return 0 if value == 0 else 1 << (value.bit_length() - 1)


def _answers(values: Sequence[int], input_length: int | None) -> bytes | None:
    parsed = _parse(values, False, input_length)
    if parsed is None:
        return None
    _, parent, preorder, order, queries = parsed
    n = len(order)

    # Preorder labels are propagated bottom-up by their largest low bit.
    inlabel = preorder.copy()
    for node in reversed(order[1:]):
        p = parent[node]
        if _lowbit(inlabel[p]) < _lowbit(inlabel[node]):
            inlabel[p] = inlabel[node]

    # Each ascendant mask records the inlabel-path levels on the root path.
    ascendant = [0] * n
    path_parent = [0] * n
    for node in order:
        p = parent[node]
        if p < 0:
            ascendant[node] = _lowbit(inlabel[node])
            path_parent[preorder[node] - 1] = node
        else:
            ascendant[node] = ascendant[p] | _lowbit(inlabel[node])
            path_parent[preorder[node] - 1] = (
                p if inlabel[node] != inlabel[p] else path_parent[preorder[p] - 1]
            )

    result = bytearray()
    for u, v in queries:
        lu, lv = _lowbit(inlabel[u]), _lowbit(inlabel[v])
        mask = _highbit((inlabel[u] ^ inlabel[v]) | lu | lv) - 1
        shared = _lowbit(ascendant[u] & ascendant[v] & ~mask)
        if shared == 0:
            return None
        x, y = u, v
        if shared != lu:
            mask = _highbit(ascendant[u] & (shared - 1)) - 1
            index = ((preorder[u] & ~mask) | (mask + 1)) - 1
            x = path_parent[index]
        if shared != lv:
            mask = _highbit(ascendant[v] & (shared - 1)) - 1
            index = ((preorder[v] & ~mask) | (mask + 1)) - 1
            y = path_parent[index]
        result.append(x if preorder[x] < preorder[y] else y)
    return bytes(result)


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
    effective_capacity = MAX_QUERIES if capacity is None else capacity
    queries = parsed[-1]
    if type(output_is_null) is not bool or type(effective_capacity) is not int or effective_capacity < 0:
        return -2, b""
    if effective_capacity < len(queries) or (output_is_null and queries):
        return -2, b""
    answers = _answers(values, input_length)
    if answers is None:
        return -1, b""
    return len(answers), answers
