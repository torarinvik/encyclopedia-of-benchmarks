"""Kruskal reconstruction tree with binary-lifted LCA bottleneck queries."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_M = 16
MAX_Q = 8
MAX_WEIGHT = 1_000_000
MAX_VALID_INPUT_LENGTH = 3 + 3 * MAX_M + 2 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = 36_000_072
WORKSPACE_BYTES = 4096


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, edge_count, query_count = values[:3]
    if (not 1 <= n <= MAX_N or not 0 <= edge_count <= MAX_M
            or not 1 <= query_count <= MAX_Q
            or len(values) != 3 + 3 * edge_count + 2 * query_count):
        return None
    cursor = 3
    edges: list[tuple[int, int, int, int]] = []
    for index in range(edge_count):
        left, right, weight = values[cursor:cursor + 3]
        cursor += 3
        if not 0 <= left < n or not 0 <= right < n or not 0 <= weight <= MAX_WEIGHT:
            return None
        edges.append((weight, index, left, right))
    queries: list[tuple[int, int]] = []
    for _ in range(query_count):
        left, right = values[cursor:cursor + 2]
        cursor += 2
        if not 0 <= left < n or not 0 <= right < n:
            return None
        queries.append((left, right))
    return n, edges, queries


def _find(parent: list[int], vertex: int) -> int:
    root = vertex
    while parent[root] != root:
        root = parent[root]
    while parent[vertex] != vertex:
        next_vertex = parent[vertex]
        parent[vertex] = root
        vertex = next_vertex
    return root


def _reconstruction_tree(n: int, edges: Sequence[tuple[int, int, int, int]]):
    capacity = 2 * n - 1
    children = [[-1, -1] for _ in range(capacity)]
    tree_parent = [-1] * capacity
    merge_weight = [0] * capacity
    dsu_parent = list(range(n))
    dsu_size = [1] * n
    component_tree_root = list(range(n))
    next_node = n

    for weight, _, left, right in sorted(edges):
        root_left = _find(dsu_parent, left)
        root_right = _find(dsu_parent, right)
        if root_left == root_right:
            continue
        tree_left = component_tree_root[root_left]
        tree_right = component_tree_root[root_right]
        children[next_node] = [tree_left, tree_right]
        tree_parent[tree_left] = next_node
        tree_parent[tree_right] = next_node
        merge_weight[next_node] = weight
        if dsu_size[root_left] < dsu_size[root_right]:
            root_left, root_right = root_right, root_left
        dsu_parent[root_right] = root_left
        dsu_size[root_left] += dsu_size[root_right]
        component_tree_root[root_left] = next_node
        next_node += 1

    children = children[:next_node]
    tree_parent = tree_parent[:next_node]
    merge_weight = merge_weight[:next_node]
    depth = [0] * next_node
    levels = max(1, next_node.bit_length())
    ancestor = [[0] * next_node for _ in range(levels)]
    roots = [node for node, parent in enumerate(tree_parent) if parent < 0]
    for root in roots:
        ancestor[0][root] = root
        stack = [root]
        while stack:
            node = stack.pop()
            for child in children[node]:
                if child < 0:
                    continue
                depth[child] = depth[node] + 1
                ancestor[0][child] = node
                stack.append(child)
    for level in range(1, levels):
        for node in range(next_node):
            ancestor[level][node] = ancestor[level - 1][ancestor[level - 1][node]]
    return (next_node, children, tree_parent, merge_weight, depth, ancestor,
            dsu_parent)


def _lca(left: int, right: int, depth: Sequence[int],
         ancestor: Sequence[Sequence[int]]) -> int:
    if depth[left] < depth[right]:
        left, right = right, left
    difference = depth[left] - depth[right]
    bit = 0
    while difference:
        if difference & 1:
            left = ancestor[bit][left]
        difference >>= 1
        bit += 1
    if left == right:
        return left
    for level in range(len(ancestor) - 1, -1, -1):
        if ancestor[level][left] != ancestor[level][right]:
            left = ancestor[level][left]
            right = ancestor[level][right]
    return ancestor[0][left]


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, edges, queries = parsed
    (_, _, _, merge_weight, depth, ancestor,
     dsu_parent) = _reconstruction_tree(n, edges)
    checksum = 0
    for index, (left, right) in enumerate(queries):
        if left == right:
            answer = 0
        elif _find(dsu_parent, left) != _find(dsu_parent, right):
            answer = -1
        else:
            answer = merge_weight[_lca(left, right, depth, ancestor)]
        checksum += (index + 1) * (answer + 2)
    return checksum
